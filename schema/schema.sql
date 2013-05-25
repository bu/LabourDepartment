CREATE TABLE `build_results` (
  `bundle` varchar(32) NOT NULL DEFAULT '',
  `build_number` int(11) NOT NULL,
  `result` tinyint(1) NOT NULL DEFAULT '0',
  KEY `bundle` (`bundle`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
