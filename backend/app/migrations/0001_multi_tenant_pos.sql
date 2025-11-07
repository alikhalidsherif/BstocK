-- Migration: Multi-tenant POS schema overhaul
-- Applies to PostgreSQL. For SQLite, adapt types accordingly.

BEGIN;

-- Drop obsolete tables from the legacy change request workflow
DROP TABLE IF EXISTS change_requests CASCADE;
DROP TABLE IF EXISTS change_history CASCADE;

-- Drop legacy enums if they exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'userrole') THEN
        DROP TYPE userrole;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'paymentstatus') THEN
        DROP TYPE paymentstatus;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'changerequeststatus') THEN
        DROP TYPE changerequeststatus;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'changerequestaction') THEN
        DROP TYPE changerequestaction;
    END IF;
END$$;

-- Create enums
CREATE TYPE user_role AS ENUM ('owner', 'cashier');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'mobile', 'bank_transfer');

-- Organizations table
CREATE TABLE IF NOT EXISTS organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    owner_id INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Users table (recreated with organization scoping)
DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'cashier',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (username)
);

ALTER TABLE organizations
    ADD CONSTRAINT organizations_owner_id_fkey
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL;

-- Products table (base products)
DROP TABLE IF EXISTS products CASCADE;
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);
CREATE INDEX idx_products_org_id ON products (organization_id);
CREATE INDEX idx_products_org_category ON products (organization_id, category);

-- Variants table (sellable items)
DROP TABLE IF EXISTS variants CASCADE;
CREATE TABLE variants (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sku VARCHAR(100) NOT NULL UNIQUE,
    barcode VARCHAR(100) UNIQUE,
    attributes JSONB,
    purchase_price NUMERIC(10,2) NOT NULL DEFAULT 0,
    sale_price NUMERIC(10,2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    min_stock_level INTEGER NOT NULL DEFAULT 0,
    unit_type VARCHAR(20) NOT NULL DEFAULT 'pcs',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);
CREATE INDEX idx_variants_product_id ON variants (product_id);
CREATE INDEX idx_variants_barcode ON variants (barcode);
CREATE INDEX idx_variants_sku ON variants (sku);

-- Vendors table
DROP TABLE IF EXISTS vendors CASCADE;
CREATE TABLE vendors (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_vendors_org_id ON vendors (organization_id);

-- Customers table
DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    email VARCHAR(255),
    address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_customers_org_id ON customers (organization_id);
CREATE INDEX idx_customers_phone ON customers (phone);

-- Sales table
DROP TABLE IF EXISTS sales CASCADE;
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    cashier_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL,
    subtotal NUMERIC(10,2) NOT NULL,
    tax NUMERIC(10,2) NOT NULL DEFAULT 0,
    discount NUMERIC(10,2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(10,2) NOT NULL,
    profit NUMERIC(10,2) NOT NULL,
    payment_method payment_method NOT NULL,
    payment_proof_url VARCHAR(500),
    notes TEXT,
    synced BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_sales_org_id ON sales (organization_id);
CREATE INDEX idx_sales_created_at ON sales (created_at);
CREATE INDEX idx_sales_org_date ON sales (organization_id, created_at);

-- Sale items table
DROP TABLE IF EXISTS sale_items CASCADE;
CREATE TABLE sale_items (
    id SERIAL PRIMARY KEY,
    sale_id INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    variant_id INTEGER NOT NULL REFERENCES variants(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL,
    price_at_sale NUMERIC(10,2) NOT NULL,
    purchase_price_at_sale NUMERIC(10,2) NOT NULL
);
CREATE INDEX idx_sale_items_sale_id ON sale_items (sale_id);
CREATE INDEX idx_sale_items_variant_id ON sale_items (variant_id);

COMMIT;
