CREATE TABLE statut_fantoir (
	fantoir character varying(10),
	id_statut integer,
	timestamp_statut double precision,
	insee_com character(5));

CREATE INDEX idx_statut_fantoir_insee ON statut_fantoir(insee_com);
CREATE INDEX idx_statut_fantoir_fantoir ON statut_fantoir(fantoir);

CREATE TABLE labels_statuts_fantoir(
	id_statut integer primary key,
	tri integer default 0,
	label_statut character varying(200)
);

INSERT INTO labels_statuts_fantoir (id_statut,tri,label_statut)
VALUES (0,0,'Ok'),
(1,1,'Erreur d''orthographe'),
(2,2,'Divergence d''orthographe'),
(3,3,'Nom différent'),
(4,4,'Type de voie différent'),
(5,5,'Voie doublon et type de voie différent'),
(6,6,'Voie doublon avec orthographe différente'),
(7,7,'Répétition du type de voie'),
(8,8,'Nom introuvable sur le terrain'),
(9,9,'Ancien nom supprimé sur le terrain'),
(10,99,'Erreurs combinées'),
(11,15,'Adresses hors périmètre'),
(12,10,'Voie détruite'),
(13,11,'Voie incorporée à une autre'),
(14,12,'Voie inexistante')
;
