/* Nombre de participants */
#define N 10

/* État organisateur */
mtype = { attenteDebutO, debutOffre, enOffre, finTour, finOffre, finEnchere };
/* État participant */
mtype = { attenteDebutP, pret, nonPreneur, preneur, perdant };
/* Messages */
mtype = { debutEnchere, offre, achat, refus };
/* États */
mtype etatO;
/* Canaux */
chan cOtoP = [N] of { mtype };
chan cPtoO = [N] of { mtype };
/* Variables */
int prix = 100;
int seuil = 10;
int decrement = 5;
int acheteur = -1;

/* Processus organisateur */
proctype organisateur() {
	etatO = attenteDebutO;
	do
	:: (etatO == attenteDebutO) ->
		printf("Attente début enchère\n");
		int i;
		for (i : 0 .. N - 1) {
			cPtoO?pret;
		}
		for (i : 0 .. N - 1) {
			cOtoP!debutEnchere;
		}
		printf("Enchère debutée\n");
		etatO = debutOffre;
	:: (etatO == debutOffre) ->
		int i2;
		for (i2 : 0 .. N - 1) {
			cOtoP!offre;
			if
			:: cPtoO?achat ->
				printf("Achat du participant %d pour %d\n", acheteur, prix);
				int j;
				for (j : 0 .. N - 1) {
					cOtoP!finEnchere;
				}
				etatO = finEnchere;
				goto L1;
			:: cPtoO?refus ->
				skip;
			fi;
		}
		prix = prix - decrement;
		for (i2 : 0 .. N - 1) {
			cOtoP!finTour;
		}
L1:		skip;
	:: (etatO == finEnchere) ->
		break;
	od;
}

/* Processus participant */
proctype participant(int n) {
	mtype etatP;
	etatP = attenteDebutP;
	do
	:: (etatP == attenteDebutP) ->
		cPtoO!pret;
		printf("Participant %d en attente du début de l'enchère\n", n);
		cOtoP?debutEnchere;
		printf("Enchère débutée pour le participant %d\n", n);
		etatP = pret;
	:: (etatP == pret) ->
		if
		:: cOtoP?offre ->
			if
			:: (prix <= seuil) ->
				acheteur = n;
				cPtoO!achat;
				etatP = preneur;
				goto L0;
			:: else
			fi;
			atomic {
				if
				:: skip ->;
					acheteur = n;
					cPtoO!achat;
					etatP = preneur;
				:: skip ->
					cPtoO!refus;
					etatP = nonPreneur;
				fi;
			}
L0:			skip;
		:: cOtoP?finEnchere ->
			etatP = perdant;
		fi;
	:: (etatP == preneur) ->
		if
		:: cOtoP?finEnchere -> break;
		fi;
	:: (etatP == nonPreneur) ->
		if
		:: cOtoP?finTour ->
			etatP = pret;
		:: cOtoP?finEnchere ->
			etatP = perdant;
			break;
		fi;
	od;
}

/* Initialisation */
init {
	atomic {
		run organisateur();
		int i;
		for (i : 0 .. N - 1) {
			run participant(i);
		}
	}
}
