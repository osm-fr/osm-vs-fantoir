INSERT INTO statut_fantoir
VALUES ('__fantoir__',__statut__,(SELECT EXTRACT(epoch from now())::integer),'__code_insee__');
