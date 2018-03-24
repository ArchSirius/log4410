/* état du participant 1 */
mtype = { attenteDebut1, enCours1, enAttente1, perdant1, gagnant1 };
/* état du participant 2 */
mtype = { attenteDebut2, enCours2, enAttente2, perdant2, gagnant2 };
/* état organisateur */
mtype = { attenteDebutO, attenteDe1, attenteDe2, finEnchere };
/* évènement */
mtype = { debutEnchere, participantPret, abandon, gagnant, perdant, encherir, doitRepondre };
mtype etatO;
mtype etat1;
mtype etat2;
/* canaux de communication de l'organisateur vers les participants */
chan mOrgaTo1 = [0] of { mtype };
chan mOrgaTo2 = [0] of { mtype };
/* canaux de communication des participants vers l'organisateur */
chan m1ToOrga = [0] of { mtype };
chan m2ToOrga = [0] of { mtype };
/* plus haut encherisseur */
int highestBidder = 0;
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
		m2ToOrga?participantPret;
		mOrgaTo1!debutEnchere;
		mOrgaTo2!debutEnchere;
		printf("Encheres debutés !\n");
		etatO = attenteDe1;
	:: (etatO == attenteDe1) ->
		printf("en attente d'une réponse du participant 1 ...\n");
		mOrgaTo1!doitRepondre;
		if
		:: m1ToOrga?encherir ->
			printf("sur-enchère du participant 1 !\n");
			prix = prix + increment;
			highestBidder = 1;
			etatO = attenteDe2;
		:: m1ToOrga?abandon ->
			printf("Le participant 1 abandonne !\n");
			mOrgaTo1!perdant; 
			if
			:: highestBidder == 2 ->
				printf("victoire du participant 2\n")
				mOrgaTo2!gagnant;
				etatO = finEnchere;
				break;
			fi
			etatO = attenteDe2;
		fi;
	:: (etatO == attenteDe2) ->
		printf("en attente d'une réponse du participant 2 ...\n");
		mOrgaTo2!doitRepondre;
		if
		:: m2ToOrga?encherir ->
			printf("sur-enchère du participant 2 !\n");
			prix = prix + increment;
			highestBidder = 2;
			etatO = attenteDe1;
		:: m2ToOrga?abandon ->
			printf("Le participant 2 abandonne !\n");
			mOrgaTo2!perdant; 
			if
			:: highestBidder == 1 ->
				printf("victoire du participant 1\n");
				mOrgaTo1!gagnant;
				etatO = finEnchere;
				break;
			:: highestBidder == 0 ->
				printf("item non vendu\n");
				etatO = finEnchere;
				break;
			fi
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
proctype participant2() {
	etat2 = attenteDebut2;
	do
	:: (etat2 == attenteDebut2) ->
		m2ToOrga!participantPret;
		printf("participant 2 en attente du début de l'enchère !\n");
		mOrgaTo2?debutEnchere;
		printf("Enchère débutée pour le participant 2 !\n");
		etat2 = enAttente2;
	:: (etat2 == enCours2) ->
		atomic {
			if
			:: skip -> m2ToOrga!encherir;
			:: skip -> m2ToOrga!abandon;
			fi; 
		}
		etat2 = enAttente2;
	:: (etat2 == enAttente2) ->
		if
		:: mOrgaTo2?doitRepondre -> etat2 = enCours2;
		:: mOrgaTo2?gagnant -> etat2 = gagnant2;
		:: mOrgaTo2?perdant -> etat2 = perdant2;
		fi;
	:: (etat2 == gagnant2) ->
		printf("Le participant 2 remporte l'enchère !\n");
		break;
	:: (etat2 == perdant2) ->
		printf("Le participant 2 se retire.\n");
		break;
	od;
}
init {
	atomic {
		run organisateur();
		run participant1();
		run participant2();
	}
}

ltl fin { [](<>(etatO == finEnchere)) }
