/* état du participant 1 */
mtype = { attenteDebut1, enCours1, enAttente1, perdant1, gagnant1 };
/* état organisateur */
mtype = { attenteDebutO, attenteDe1, finEnchere };
/* évènement */
mtype = { debutEnchere, participantPret, abandon, gagnant, perdant, encherir, doitRepondre };
mtype etatO;
mtype etat1;
mtype etat2;
/* canaux de communication de l'organisateur vers les participants */
chan mOrgaTo1 = [0] of { mtype };
/* canaux de communication des participants vers l'organisateur */
chan m1ToOrga = [0] of { mtype };

int prixDepart = 10;
int prix = prixDepart;
int increment = 5;

	
/* processus organisateur */
proctype organisateur() {
	etatO = attenteDebutO;
	do
	:: (etatO == attenteDebutO) ->
		printf("Attente debut enchere\n");
		m1ToOrga?participantPret;
		mOrgaTo1!debutEnchere;
		printf("Encheres debutés !\n");
		etatO = attenteDe1;
	:: (etatO == attenteDe1) ->
		printf("en attente d'une réponse du participant 1 ...\n");
		mOrgaTo1!doitRepondre;
		if
		:: m1ToOrga?encherir ->
			printf("sur-enchère du participant 1 !\n");
			prix = prix + increment;
			mOrgaTo1!gagnant; 
			etatO = finEnchere;
		:: m1ToOrga?abandon ->
			printf("Le participant 1 abandonne !\n");
			mOrgaTo1!perdant; 
			etatO = finEnchere;
		fi;
	:: (etatO == finEnchere) ->
		printf("Enchere terminé !\n");
		break;
	od;
}

/* processus participant */
proctype participant1() {
	etat1 = attenteDebut1;
	do
	:: (etat1 == attenteDebut1) ->
		m1ToOrga!participantPret;
		printf("participant 1 en attente du début de l'enchère !\n");
		mOrgaTo1?debutEnchere;
		printf("Enchère débutée pour le participant 1 !\n");
		etat1 = enAttente1;
	:: (etat1 == enCours1) ->
		atomic {
			if
			:: skip -> m1ToOrga!encherir;
			:: skip -> m1ToOrga!abandon;
			fi; 
		}
		etat1 = enAttente1;
	:: (etat1 == enAttente1) ->
		if
		:: mOrgaTo1?doitRepondre -> etat1 = enCours1;
		:: mOrgaTo1?gagnant -> etat1 = gagnant1;
		:: mOrgaTo1?perdant -> etat1 = perdant1;
		fi;
	:: (etat1 == gagnant1) ->
		printf("Le participant 1 remporte l'enchère !\n");
		break;
	:: (etat1 == perdant1) ->
		printf("Le participant 1 se retire.\n");
		break;
	od;
}

init {
	atomic {
		run organisateur();
		run participant1();
	}
}
