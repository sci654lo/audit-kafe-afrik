/* Partie 1 � Extraction cibl�e (niveau interm�diaire) */

-- 1 Extraire toutes les lignes du journal du mois de mars 2024.
SELECT	date_piece,
		journal_code,
		numero_piece,
		compte,
		libelle,
		tiers,
		debit,
		credit,
		CASE 
		WHEN debit > 0 THEN 'D�bit'
		WHEN credit > 0 THEN 'Cr�dit'
		ELSE ''
		END AS type_mouvement
FROM [dbo].[journal_comptable_2024]
WHERE date_piece BETWEEN '2024-03-01' AND '2024-03-31' -- optimisation: utiliser une plage de dates explicite
ORDER BY date_piece;
		
-- 2 Lister toutes les �critures du journal "ACH" dont le montant au d�bit est sup�rieur � 200 000 FCFA.
SELECT	date_piece,
		journal_code,
		numero_piece,
		compte,
		libelle,
		tiers,
		debit,
		credit
FROM [dbo].[journal_comptable_2024]
WHERE journal_code = 'ACH' 
	AND debit > 200000
	AND compte LIKE '60%'; -- exclure les lignes de contrepartie


-- 3 Obtenir les 5 plus gros montants d�bit�s sur un compte de classe 6.
SELECT TOP (5) date_piece,
				journal_code,
				numero_piece,
				compte,
				libelle,
				tiers,
				debit,
				credit
FROM [dbo].[journal_comptable_2024]
WHERE compte LIKE '6%'
	AND debit > 0
ORDER BY debit DESC;

-- 4 Lister les op�rations sans tiers renseign� (tiers IS NULL).
SELECT	date_piece,
		journal_code,
		numero_piece,
		compte,
		libelle,
		tiers,
		debit,
		credit,
		'Aucun tiers associ�' AS Anomalie_detectee
FROM [dbo].[journal_comptable_2024]
WHERE tiers IS NULL
ORDER BY date_piece;

-- 5 Afficher tous les libell�s contenant le mot "caf�", sans tenir compte de la casse.
SELECT	date_piece,
		journal_code,
		numero_piece,
		compte,
		libelle,
		tiers,
		debit,
		credit
FROM [dbo].[journal_comptable_2024]
WHERE libelle COLLATE Latin1_General_CI_AI LIKE '%caf�%' -- CI : Case insensitive et AI: Accent insensitive Latin1_General: jeu de caract�res occidentale classique
ORDER BY date_piece;


-- 6 Compter combien d��critures concernent le compte 4456 (TVA d�ductible).
SELECT COUNT(*) AS [TVA D�ductible]
FROM [dbo].[journal_comptable_2024]
WHERE compte LIKE '4456%';

-- BONUS Combien d��critures dans le journal comptable n�ont pas de tiers renseign� (tiers IS NULL) ?
SELECT COUNT(*) AS Aucun_tiers_associ�
FROM [dbo].[journal_comptable_2024]
WHERE tiers IS NULL;


-- 7 Obtenir les montants moyens d�bit�s par journal (ordre d�croissant).
SELECT	journal_code, 
		AVG(debit) AS montant_moyen
FROM [dbo].[journal_comptable_2024]
WHERE debit IS NOT NULL -- G�rer les Null car fonction moyenne AVG() utilis�e
GROUP BY journal_code
ORDER BY montant_moyen DESC;

-- 8 Pour chaque compte de classe 6, calculer la somme totale des d�bits.
SELECT	compte, 
		SUM(debit) AS total
FROM [dbo].[journal_comptable_2024]
WHERE compte LIKE '6%' -- Ordre de priorit� HAVING et WHERE 
GROUP BY compte
ORDER BY total DESC;

-- 9 Identifier tous les comptes utilis�s en 2024 mais absents du plan comptable.
SELECT	jc.date_piece,
		jc.journal_code,
		jc.compte AS numero_jc, 
		jc.libelle,
		pc.compte AS numero_pc
FROM [dbo].[journal_comptable_2024] jc LEFT JOIN [dbo].[plan_comptable] pc 
	ON jc.compte = pc.compte
WHERE pc.compte IS NULL
ORDER BY jc.compte ASC;

-- 10 Lister les op�rations o� d�bit = cr�dit (erreur potentielle ou reclassement).
SELECT	date_piece,
		journal_code,
		numero_piece,
		compte,
		libelle,
		tiers,
		debit,
		credit
FROM [dbo].[journal_comptable_2024]
WHERE debit = credit;


/* Partie 2 � Requ�tes avanc�es avec jointures et logique comptable */

-- 11 Rejoindre journal_comptable_2024 et plan_comptable pour afficher compte, intitule, debit, credit.
SELECT	jc.compte,
		pc.intitule,
		jc.debit,
		jc.credit
FROM [dbo].[journal_comptable_2024] jc LEFT JOIN [dbo].[plan_comptable] pc ON jc.compte = pc.compte --Pour detecter les anomalies utiliser le LEFT JOIN
ORDER BY jc.compte;


-- 12 Rejoindre le journal avec la table tiers pour identifier toutes les �critures li�es � des CLIENTS.
SELECT	jc.date_piece,
		jc.journal_code,
		jc.numero_piece,
		jc.compte,
		jc.debit,
		jc.credit,
		tr.code_tiers,
		tr.nom_tiers
FROM [dbo].[journal_comptable_2024] jc LEFT JOIN [dbo].[tiers] tr ON jc.tiers = tr.code_tiers
WHERE jc.compte LIKE '41%' OR jc.compte LIKE '419%'
ORDER BY jc.date_piece;


-- 13 Cr�er une vue journal_mars contenant toutes les op�rations de mars avec leur intitule de compte.
CREATE VIEW journal_mars AS
SELECT	jc.date_piece,
		jc.journal_code,
		jc.numero_piece,
		jc.compte,
		pc.intitule,
		jc.libelle,
		jc.tiers,
		jc.debit,
		jc.credit
FROM [dbo].[journal_comptable_2024] jc LEFT JOIN [dbo].[plan_comptable] pc ON jc.compte = pc.compte
WHERE jc.date_piece BETWEEN '2024-03-01' AND '2024-03-31';

-- 14 Afficher les comptes de classe 7 (produits) avec un cr�dit cumul� > 1 000 000 FCFA.
SELECT	jc.compte,
		SUM(jc.credit) AS Total_credit
FROM [dbo].[journal_comptable_2024] jc
WHERE jc.compte LIKE '7%'
GROUP BY jc.compte
HAVING SUM(jc.credit) > 1000000;

-- 15 Lister les comptes qui ont �t� mouvement�s uniquement au d�bit, jamais au cr�dit.
SELECT compte
FROM [dbo].[journal_comptable_2024]
GROUP BY compte
HAVING SUM(debit) > 0 AND SUM(credit) = 0;

-- 16 Identifier les journaux comptables dans lesquels des �critures � 0 FCFA ont �t� pass�es.
SELECT journal_code, COUNT(*) AS nombre_anomalies
FROM [dbo].[journal_comptable_2024]
WHERE credit = 0 AND debit = 0
GROUP BY journal_code
ORDER BY nombre_anomalies DESC;

-- 17 Calculer, pour chaque tiers fournisseur, la somme des achats (journal "ACH") en 2024.
SELECT	jc.tiers, 
		tr.nom_tiers, 
		SUM(jc.debit) AS total_achats_2024
FROM [dbo].[journal_comptable_2024] jc LEFT JOIN [dbo].[tiers] tr ON jc.tiers = tr.code_tiers
WHERE tr.type_tiers = 'FOURNISSEUR' AND jc.journal_code = 'ACH' AND YEAR(jc.date_piece) = '2024'
GROUP BY jc.tiers, tr.nom_tiers;

-- 18 Cr�er une requ�te qui marque comme "SUSPICIEUX" tout mouvement > 500 000 FCFA au d�bit et sans tiers renseign�.
SELECT	jc.date_piece,
		jc.journal_code,
		jc.numero_piece,
		jc.compte,
		jc.libelle,
		jc.tiers,
		jc.debit,
		jc.credit,
		CASE 
		WHEN debit > 500000 AND tiers IS NULL THEN 'Suspicieux'
		ELSE 'RAS'
		END AS Observations
FROM [dbo].[journal_comptable_2024] jc
ORDER BY jc.date_piece;

-- 19 Extraire les comptes o� la somme cr�dit � somme d�bit est > 0 (exc�dent).
SELECT	jc.compte,
		SUM(jc.debit) AS total_debit,
		SUM(jc.credit) AS total_credit, 
		CASE  
		WHEN SUM(jc.debit) - SUM(jc.credit) > 0 THEN 'd�biteur' 
		WHEN SUM(jc.debit) - SUM(jc.credit) < 0 THEN 'cr�diteur' 
		ELSE 'nul'
		END AS Solde
FROM [dbo].[journal_comptable_2024] jc
GROUP BY jc.compte
HAVING  SUM(jc.credit) - SUM(jc.debit) > 0;



-- 20 Cr�er une table temporaire contenant les 10 op�rations suspectes les plus �lev�es (montant + absence tiers ou compte anormal).
SELECT TOP(10)	jc.date_piece,
				jc.journal_code,
				jc.numero_piece,
				jc.compte,
				pc.intitule,
				jc.libelle,
				jc.tiers,
				jc.debit,
				jc.credit
INTO #operations_suspectes
FROM [dbo].[journal_comptable_2024] jc LEFT JOIN [dbo].[plan_comptable] pc ON jc.compte = pc.compte
WHERE jc.tiers IS NULL OR pc.compte IS NULL
ORDER BY jc.debit DESC, jc.credit DESC;

SELECT *
FROM #operations_suspectes;
				
				
