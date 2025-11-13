-- =====================================================
-- Database: panel4all_boutique
-- =====================================================

-- Drop existing tables if they exist
DROP TABLE IF EXISTS user_purchases;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;

-- Create roles table
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    permissions JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    avatar VARCHAR(255),
    balance DECIMAL(10, 2) DEFAULT 0.00,
    role_id INT NOT NULL DEFAULT 2,
    status ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
    email_verified_at TIMESTAMP NULL,
    last_login_at TIMESTAMP NULL,
    last_login_ip VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT
);

-- Create categories table
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    image VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL UNIQUE,
    description TEXT,
    category_id INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    sku VARCHAR(100) UNIQUE,
    images JSON,
    features JSON,
    is_active BOOLEAN DEFAULT TRUE,
    featured BOOLEAN DEFAULT FALSE,
    views INT DEFAULT 0,
    sales_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
);

-- Create user_purchases table
CREATE TABLE user_purchases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10, 2) NOT NULL,
    duration_months INT,
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'completed',
    transaction_id VARCHAR(100),
    payment_method VARCHAR(50),
    payment_reference VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
);

-- Create indexes for better performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_purchases_user_id ON user_purchases(user_id);
CREATE INDEX idx_purchases_product_id ON user_purchases(product_id);
CREATE INDEX idx_purchases_status ON user_purchases(status);
CREATE INDEX idx_purchases_date ON user_purchases(purchase_date);

-- Create triggers for updating statistics
DELIMITER //
CREATE TRIGGER update_product_sales_after_purchase
AFTER INSERT ON user_purchases
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE products
        SET sales_count = sales_count + 1
        WHERE id = NEW.product_id;
    END IF;
END//

CREATE TRIGGER update_product_stock_after_purchase
AFTER INSERT ON user_purchases
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE products
        SET stock = stock - 1
        WHERE id = NEW.product_id;
    END IF;
END//

DELIMITER ;

-- Insert default data

-- Insert roles
INSERT INTO roles (id, name, description, permissions) VALUES
(1, 'admin', 'Super administrator with all permissions', '["read", "write", "delete", "admin", "manage_users", "manage_products", "manage_transactions", "view_reports"]'),
(2, 'user', 'Regular user with basic permissions', '["read", "purchase"]'),
(3, 'moderator', 'Moderator with limited admin permissions', '["read", "write", "delete", "manage_users", "view_reports"]');

-- Insert admin user (password: admin123 - hashed)
INSERT INTO users (username, email, password_hash, full_name, role_id, status, balance) VALUES
('admin', 'admin@panel.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDrPNYm7mDWcLjW', 'Administrator', 1, 'active', 9500.00);

-- Insert sample users
INSERT INTO users (username, email, password_hash, full_name, phone, role_id, status, balance) VALUES
('testuser', 'test@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDrPNYm7mDWcLjW', 'Test User', '+212 612 345 678', 2, 'active', 1500.00),
('moderator', 'moderator@panel.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDrPNYm7mDWcLjW', 'Moderator User', '+212 623 456 789', 3, 'active', 2500.00),
('demo_user', 'demo@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewDrPNYm7mDWcLjW', 'Demo User', '+212 634 567 890', 2, 'active', 750.00);

-- Insert categories
INSERT INTO categories (name, slug, description) VALUES
('IPTV', 'iptv', 'Services IPTV avec chaînes internationales et locales'),
('M3U', 'm3u', 'Fichiers M3U pour lecteurs multimédias'),
('Premium', 'premium', 'Contenu premium exclusif et de haute qualité'),
('Abonnement', 'abonnement', 'Abonnements récurrents pour services continus'),
('Service', 'service', 'Services d\'installation et de configuration');

-- Insert products
INSERT INTO products (name, slug, description, category_id, price, stock, sku, is_active) VALUES
('M3U Premium 12 mois', 'm3u-premium-12-mois', 'Accès à 10 000 chaînes IPTV qualité HD, 12 mois de service', 2, 799.99, 15, 'M3U-PREM-12', TRUE),
('IPTV Basic', 'iptv-basic', 'Package IPTV basique avec 500 chaînes de base', 1, 99.99, 5, 'IPTV-BASIC-1', TRUE),
('IPTV Pro', 'iptv-pro', 'Package IPTV professionnel avec 2000 chaînes et VOD', 1, 199.99, 25, 'IPTV-PRO-1', TRUE),
('Premium Mensuel', 'premium-mensuel', 'Contenu premium exclusif mis à jour mensuellement', 3, 299.99, 30, 'PREMIUM-MOIS', TRUE),
('Premium Trimestriel', 'premium-trimestriel', 'Accès premium pour 3 mois avec contenu exclusif', 3, 799.99, 20, 'PREMIUM-TRIM', TRUE),
('Premium Annuel', 'premium-annuel', 'Toute l\'année de contenu premium à prix réduit', 3, 2499.99, 10, 'PREMIUM-AN', TRUE),
('Abonnement Annuel', 'abonnement-annuel', 'Abonnement annuel pour services continus', 4, 1499.99, 25, 'AB-ANNUAL-1', TRUE),
('Abonnement Mensuel', 'abonnement-mensuel', 'Abonnement mensuel flexible', 4, 149.99, 50, 'AB-MOIS-1', TRUE),
('Installation IPTV', 'installation-iptv', 'Service professionnel d\'installation et de configuration', 5, 499.99, 10, 'INST-IPTV-1', TRUE),
('Support Premium', 'support-premium', 'Support technique premium 24/7', 5, 299.99, 20, 'SUPPORT-PREM', TRUE);

-- Insert sample purchases
INSERT INTO user_purchases (user_id, product_id, amount, duration_months, status, payment_method) VALUES
(2, 1, 799.99, 12, 'completed', 'CIH'),
(3, 4, 299.99, 1, 'completed', 'BMCI'),
(4, 2, 99.99, 1, 'completed', 'CIH'),
(2, 5, 799.99, 3, 'completed', 'MASTERCARD'),
(1, 6, 2499.99, 12, 'completed', 'CIH'),
(4, 7, 1499.99, 12, 'completed', 'BMCI'),
(3, 8, 149.99, 1, 'completed', 'CIH'),
(2, 9, 499.99, 1, 'completed', 'MASTERCARD'),
(1, 10, 299.99, 1, 'completed', 'CIH'),
(4, 3, 199.99, 1, 'completed', 'BMCI');

-- Create views for reporting
CREATE VIEW total_revenue AS
SELECT SUM(amount) as total FROM user_purchases WHERE status = 'completed';

CREATE VIEW monthly_revenue AS
SELECT
    YEAR(purchase_date) as year,
    MONTH(purchase_date) as month,
    SUM(amount) as revenue,
    COUNT(*) as transactions
FROM user_purchases
WHERE status = 'completed'
GROUP BY YEAR(purchase_date), MONTH(purchase_date)
ORDER BY year DESC, month DESC;

CREATE VIEW user_statistics AS
SELECT
    u.id,
    u.username,
    u.email,
    u.balance,
    COUNT(p.id) as total_purchases,
    SUM(p.amount) as total_spent,
    MAX(p.purchase_date) as last_purchase
FROM users u
LEFT JOIN user_purchases p ON u.id = p.user_id
WHERE p.status = 'completed'
GROUP BY u.id, u.username, u.email, u.balance
ORDER by u.id;

-- Create stored procedures for common operations

DELIMITER //

CREATE PROCEDURE GetProductsByCategory(IN category_slug VARCHAR(100))
BEGIN
    SELECT p.*, c.name as category_name
    FROM products p
    JOIN categories c ON p.category_id = c.id
    WHERE c.slug = category_slug AND p.is_active = TRUE
    ORDER BY p.created_at DESC;
END//

CREATE PROCEDURE GetUserPurchases(IN user_id INT)
BEGIN
    SELECT up.*, p.name as product_name, p.slug as product_slug
    FROM user_purchases up
    JOIN products p ON up.product_id = p.id
    WHERE up.user_id = user_id
    ORDER BY up.purchase_date DESC;
END//

CREATE PROCEDURE GetLowStockProducts(IN threshold INT)
BEGIN
    SELECT p.*, c.name as category_name
    FROM products p
    JOIN categories c ON p.category_id = c.id
    WHERE p.stock <= threshold AND p.is_active = TRUE
    ORDER BY p.stock ASC;
END//

CREATE PROCEDURE AddUserPurchase(
    IN p_user_id INT,
    IN p_product_id INT,
    IN p_amount DECIMAL(10,2),
    IN p_duration_months INT,
    IN p_payment_method VARCHAR(50),
    IN p_payment_reference VARCHAR(100)
)
BEGIN
    DECLARE product_stock INT;

    -- Check product stock
    SELECT stock INTO product_stock FROM products WHERE id = p_product_id;

    IF product_stock > 0 THEN
        -- Insert purchase
        INSERT INTO user_purchases (
            user_id, product_id, amount, duration_months,
            payment_method, payment_reference, status
        ) VALUES (
            p_user_id, p_product_id, p_amount, p_duration_months,
            p_payment_method, p_payment_reference, 'completed'
        );

        -- Update stock
        UPDATE products SET stock = stock - 1 WHERE id = p_product_id;

        -- Update user balance (if recharge)
        IF p_product_id = 11 THEN -- Assuming product ID 11 is recharge
            UPDATE users SET balance = balance + p_amount WHERE id = p_user_id;
        END IF;

        SELECT 'success' as result;
    ELSE
        SELECT 'error_insufficient_stock' as result;
    END IF;
END//

DELIMITER ;

-- Grant permissions
-- CREATE USER 'panel_user'@'localhost' IDENTIFIED BY 'panel_password';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON panel4all_boutique.* TO 'panel_user'@'localhost';
-- FLUSH PRIVILEGES;

-- Add table for system settings
CREATE TABLE system_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT,
    description TEXT,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert default system settings
INSERT INTO system_settings (setting_key, setting_value, description, category) VALUES
('site_name', 'Panel 4 All', 'Nom du site', 'general'),
('site_description', 'Boutique premium de services numériques', 'Description du site', 'general'),
('admin_email', 'admin@panel.com', 'Email administrateur', 'general'),
('currency', 'MAD', 'Devise principale', 'general'),
('tax_rate', '0.00', 'Taux de taxe (%)', 'financial'),
('minimum_balance', '1000.00', 'Solde minimum requis (MAD)', 'financial'),
('recharge_bonus', '0.05', 'Bonus recharge (5%)', 'financial'),
('max_login_attempts', '5', 'Nombre maximum de tentatives de connexion', 'security'),
('password_expiry_days', '90', 'Durée d\'expiration du mot de passe (jours)', 'security'),
('session_timeout_minutes', '30', 'Délai d\'expiration de session (minutes)', 'security'),
('maintenance_mode', 'false', 'Mode maintenance', 'general');

-- Create audit log table
CREATE TABLE audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(50),
    record_id INT,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Create trigger for audit logging
DELIMITER //
CREATE TRIGGER log_user_changes
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, table_name, record_id, old_values, new_values, ip_address)
    VALUES (NEW.id, 'UPDATE', 'users', NEW.id,
            JSON_OBJECT('username', OLD.username, 'email', OLD.email, 'role_id', OLD.role_id, 'status', OLD.status),
            JSON_OBJECT('username', NEW.username, 'email', NEW.email, 'role_id', NEW.role_id, 'status', NEW.status),
            NULL);
END//

CREATE TRIGGER log_product_changes
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, table_name, record_id, old_values, new_values, ip_address)
    VALUES (NEW.id, 'UPDATE', 'products', NEW.id,
            JSON_OBJECT('name', OLD.name, 'price', OLD.price, 'stock', OLD.stock, 'status', OLD.status),
            JSON_OBJECT('name', NEW.name, 'price', NEW.price, 'stock', NEW.stock, 'status', NEW.status),
            NULL);
END//

DELIMITER ;

-- Display summary
SELECT
    'Database Setup Complete' as status,
    COUNT(*) as total_tables,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM products) as total_products,
    (SELECT COUNT(*) FROM categories) as total_categories,
    (SELECT COUNT(*) FROM user_purchases) as total_purchases;