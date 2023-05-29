INSERT INTO statut_numero
VALUES ('__numero__','__fantoir__','__source__',__statut__,(SELECT EXTRACT(epoch from now())::integer),'__code_insee__');
