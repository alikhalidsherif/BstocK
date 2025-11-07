import unittest
from decimal import Decimal

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app import crud, models, schemas
from app.database import Base


def create_test_session():
    engine = create_engine("sqlite:///:memory:", future=True)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)
    return TestingSessionLocal()


class TestSalesCalculations(unittest.TestCase):
    def test_create_sale_calculations(self):
        db = create_test_session()
        try:
            # Create organization and user
            organization = models.Organization(name="Test Org")
            db.add(organization)
            db.commit()
            db.refresh(organization)

            cashier = models.User(
                username="cashier",
                hashed_password="hashed",
                organization_id=organization.id,
                role=models.UserRole.cashier,
                is_active=True,
            )
            db.add(cashier)
            db.commit()
            db.refresh(cashier)

            # Create product and variant
            product = models.Product(
                organization_id=organization.id,
                name="Test Product",
                description="A simple product",
                category="General",
            )
            db.add(product)
            db.commit()
            db.refresh(product)

            variant = models.Variant(
                product_id=product.id,
                sku="SKU-123",
                sale_price=Decimal("100.00"),
                purchase_price=Decimal("60.00"),
                quantity=10,
                min_stock_level=2,
                unit_type="pcs",
            )
            db.add(variant)
            db.commit()
            db.refresh(variant)

            sale_data = schemas.SaleCreate(
                payment_method=models.PaymentMethod.cash,
                customer_id=None,
                notes=None,
                tax=Decimal("5.00"),
                discount=Decimal("0.00"),
                items=[
                    schemas.SaleItemInput(
                        variant_id=variant.id,
                        quantity=2,
                    )
                ],
            )

            sale = crud.create_sale(
                db=db,
                sale_data=sale_data,
                organization_id=organization.id,
                cashier_id=cashier.id,
            )

            self.assertEqual(sale.subtotal, Decimal("200.00"))
            self.assertEqual(sale.total_amount, Decimal("205.00"))
            self.assertEqual(sale.profit, Decimal("80.00"))
            self.assertEqual(sale.tax, Decimal("5.00"))
            self.assertEqual(sale.discount, Decimal("0.00"))

            db.refresh(variant)
            self.assertEqual(variant.quantity, 8)
        finally:
            db.close()
