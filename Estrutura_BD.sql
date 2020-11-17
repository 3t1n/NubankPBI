CREATE DATABASE IF NOT EXISTS nubank;
USE nubank;
CREATE TABLE IF NOT EXISTS `fatura_cartao` (
  `fatura_id` varchar(100) NOT NULL,
  `descricao` varchar(255) DEFAULT NULL,
  `categoria` varchar(100) DEFAULT NULL,
  `valor` decimal(13,2) DEFAULT NULL,
  `datetime` varchar(100),
  `origem` varchar(100) DEFAULT NULL,
  `titulo` varchar(100) DEFAULT NULL,
  `conta` varchar(100) DEFAULT NULL,
  `lat` varchar(30) DEFAULT NULL,
  `lon` varchar(30) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`fatura_id`)
);

CREATE TABLE IF NOT EXISTS `conta_corrente` (
  `id` varchar(255) NOT NULL,
  `operacao` varchar(50) DEFAULT NULL,
  `titulo` varchar(50) DEFAULT NULL,
  `detalhe` varchar(255) DEFAULT NULL,
  `data` varchar(100),
  `Valor` float DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
);
