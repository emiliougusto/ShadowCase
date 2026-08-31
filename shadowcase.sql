-- =========================================================
-- SHADOWCASE - Base MySQL (nomenclatura em português)
-- Compatível com MySQL 8+
-- Identificadores em snake_case, sem acento; tabelas no plural
-- =========================================================

CREATE DATABASE IF NOT EXISTS shadowcase
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE shadowcase;

-- ---------------------------------------------------------
-- USUÁRIOS
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL,
  senha_hash VARCHAR(255) NOT NULL,
  perfil ENUM('admin','cliente') NOT NULL DEFAULT 'cliente',
  ativo TINYINT(1) NOT NULL DEFAULT 1,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuarios_email (email)
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- ENDEREÇOS
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS enderecos (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id BIGINT UNSIGNED NOT NULL,
  apelido VARCHAR(60) NULL,
  logradouro VARCHAR(150) NOT NULL,
  numero VARCHAR(20) NOT NULL,
  complemento VARCHAR(80) NULL,
  bairro VARCHAR(80) NULL,
  cidade VARCHAR(80) NOT NULL,
  estado VARCHAR(80) NOT NULL,
  cep VARCHAR(20) NOT NULL,
  pais VARCHAR(80) NOT NULL DEFAULT 'Brasil',
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_enderecos_usuario_id (usuario_id),
  CONSTRAINT fk_enderecos_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- CATEGORIAS
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS categorias (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  slug VARCHAR(120) NOT NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categorias_slug (slug),
  UNIQUE KEY uq_categorias_nome (nome)
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- PRODUTOS
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS produtos (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_id BIGINT UNSIGNED NULL,
  nome VARCHAR(150) NOT NULL,
  slug VARCHAR(170) NOT NULL,
  descricao TEXT NULL,
  sku VARCHAR(80) NOT NULL,
  preco DECIMAL(12,2) NOT NULL,
  estoque INT NOT NULL DEFAULT 0,
  ativo TINYINT(1) NOT NULL DEFAULT 1,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_produtos_slug (slug),
  UNIQUE KEY uq_produtos_sku (sku),
  KEY idx_produtos_categoria_id (categoria_id),
  CONSTRAINT fk_produtos_categoria
    FOREIGN KEY (categoria_id) REFERENCES categorias(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- PEDIDOS
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS pedidos (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id BIGINT UNSIGNED NOT NULL,
  endereco_id BIGINT UNSIGNED NULL,
  situacao ENUM('pendente','pago','em_processamento','enviado','entregue','cancelado') NOT NULL DEFAULT 'pendente',
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  valor_frete DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  valor_desconto DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  valor_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  realizado_em DATETIME NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_pedidos_usuario_id (usuario_id),
  KEY idx_pedidos_endereco_id (endereco_id),
  KEY idx_pedidos_situacao (situacao),
  CONSTRAINT fk_pedidos_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_pedidos_endereco
    FOREIGN KEY (endereco_id) REFERENCES enderecos(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- ITENS DO PEDIDO
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS itens_pedido (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pedido_id BIGINT UNSIGNED NOT NULL,
  produto_id BIGINT UNSIGNED NOT NULL,
  quantidade INT NOT NULL,
  preco_unitario DECIMAL(12,2) NOT NULL,
  total_item DECIMAL(12,2) NOT NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_itens_pedido_pedido_id (pedido_id),
  KEY idx_itens_pedido_produto_id (produto_id),
  CONSTRAINT fk_itens_pedido_pedido
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_itens_pedido_produto
    FOREIGN KEY (produto_id) REFERENCES produtos(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- PAGAMENTOS
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS pagamentos (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pedido_id BIGINT UNSIGNED NOT NULL,
  provedor VARCHAR(50) NOT NULL,
  provedor_transacao_id VARCHAR(120) NULL,
  metodo ENUM('pix','cartao_credito','cartao_debito','boleto','carteira_digital') NOT NULL,
  situacao ENUM('pendente','autorizado','pago','falhou','estornado','cancelado') NOT NULL DEFAULT 'pendente',
  valor DECIMAL(12,2) NOT NULL,
  pago_em DATETIME NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_pagamentos_pedido_id (pedido_id),
  KEY idx_pagamentos_situacao (situacao),
  UNIQUE KEY uq_pagamentos_provedor_transacao_id (provedor_transacao_id),
  CONSTRAINT fk_pagamentos_pedido
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- SESSÕES / TOKENS (opcional para login)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS sessoes_usuario (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id BIGINT UNSIGNED NOT NULL,
  token_atualizacao_hash VARCHAR(255) NOT NULL,
  agente_usuario VARCHAR(255) NULL,
  endereco_ip VARCHAR(64) NULL,
  expira_em DATETIME NOT NULL,
  revogado_em DATETIME NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_sessoes_usuario_usuario_id (usuario_id),
  KEY idx_sessoes_usuario_expira_em (expira_em),
  CONSTRAINT fk_sessoes_usuario_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- SEED MÍNIMO
-- senha apenas EXEMPLO (troque no app)
-- ---------------------------------------------------------
INSERT INTO usuarios (nome, email, senha_hash, perfil)
VALUES ('Admin', 'admin@shadowcase.com', '$2b$10$replace_with_real_hash', 'admin')
ON DUPLICATE KEY UPDATE email = email;
