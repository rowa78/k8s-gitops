apiVersion: v1
kind: ConfigMap
metadata:
  name: init-schema
data:
  schema.sql: |
    -- Domains Tabelle
    CREATE TABLE IF NOT EXISTS virtual_domains (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50) NOT NULL
    );
    
    -- Users Tabelle
    CREATE TABLE IF NOT EXISTS virtual_users (
        id SERIAL PRIMARY KEY,
        domain_id INTEGER NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(150) NOT NULL,
        quota BIGINT NOT NULL DEFAULT 0,
        FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
    );
    
    -- Aliases Tabelle
    CREATE TABLE IF NOT EXISTS virtual_aliases (
        id SERIAL PRIMARY KEY,
        domain_id INTEGER NOT NULL,
        source VARCHAR(100) NOT NULL,
        destination VARCHAR(100) NOT NULL,
        FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
    );
    
    -- Indizes für bessere Performance
    CREATE INDEX IF NOT EXISTS idx_virtual_domains_name ON virtual_domains(name);
    CREATE INDEX IF NOT EXISTS idx_virtual_users_domain_id ON virtual_users(domain_id);
    CREATE INDEX IF NOT EXISTS idx_virtual_users_email ON virtual_users(email);
    CREATE INDEX IF NOT EXISTS idx_virtual_aliases_domain_id ON virtual_aliases(domain_id);
    CREATE INDEX IF NOT EXISTS idx_virtual_aliases_source ON virtual_aliases(source);