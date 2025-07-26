import enum
from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    DateTime,
    Boolean,
    ForeignKey,
    Enum,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base
import datetime

class UserRole(enum.Enum):
    clerk = "clerk"
    admin = "admin"
    supervisor = "supervisor"

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(Enum(UserRole), default=UserRole.clerk, nullable=False)
    is_active = Column(Boolean, default=True)

    # This relationship links a user to the change requests they have submitted.
    change_requests = relationship(
        "ChangeRequest", 
        foreign_keys="[ChangeRequest.requester_id]", 
        back_populates="requester"
    )

class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    barcode = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    price = Column(Float, nullable=False)
    quantity = Column(Integer, nullable=False)
    category = Column(String, index=True)
    
    change_requests = relationship("ChangeRequest", back_populates="product")
    history_entries = relationship("ChangeHistory", back_populates="product")


class ChangeRequestStatus(enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"

class ChangeRequestAction(enum.Enum):
    add = "add"
    update = "update"
    sell = "sell"

class PaymentStatus(enum.Enum):
    paid = "paid"
    unpaid = "unpaid"

class ChangeRequest(Base):
    __tablename__ = "change_requests"
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    requester_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    approver_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action = Column(Enum(ChangeRequestAction), nullable=False)
    quantity_change = Column(Integer, nullable=False)
    
    # Fields specific to 'sell' actions
    buyer_name = Column(String, nullable=True)
    payment_status = Column(Enum(PaymentStatus), nullable=True)
    
    status = Column(
        Enum(ChangeRequestStatus), default=ChangeRequestStatus.pending, nullable=False
    )
    request_date = Column(DateTime(timezone=True), server_default=func.now())
    approval_date = Column(DateTime(timezone=True), nullable=True)

    product = relationship("Product", back_populates="change_requests")
    requester = relationship("User", back_populates="change_requests", foreign_keys=[requester_id])
    approver = relationship("User", foreign_keys=[approver_id])

class ChangeHistory(Base):
    __tablename__ = "change_history"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity_change = Column(Integer, nullable=False)
    action = Column(Enum(ChangeRequestAction), nullable=False)
    status = Column(Enum(ChangeRequestStatus), nullable=False) # approved or rejected
    requester_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    reviewer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    product = relationship("Product", back_populates="history_entries")
    requester = relationship("User", foreign_keys=[requester_id])
    reviewer = relationship("User", foreign_keys=[reviewer_id])
