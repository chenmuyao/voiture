;La Carte Esclave
;CHEN Muyao

;les variables de l'afficheur
RS				bit		p2.6			;bit qui indique le type de donnees ehangees:
											;RS=0	instruction
											;Rs=1	donnee
							
RW				bit		p2.5			;bit qui indique:
											;RW=1 lecture	(read)
											;RW=0	ecriture	(write)
							
E				bit		p2.7			;bit de validation des donnees en entre
											;actif sur front descendant
							
LCD				equ		p0				;bus de donnees de l'afficheur

busy			bit		p0.7			;drapeau de fin d'execution d'une commande:
											;BUSY=0	terminé
											;BUSY=1	en cours



;les autres ressources

led				bit		p1.0			;led P1.0

laser			bit		p1.2			;Laser P1.2

sirene			bit		p1.3			;sirene P1.3

Rec_Balise		bit		p3.0			;Reception Infra Rouge Balise TSOP1738 p3.0

Send			bit		p3.1			;Envoie Serial(Tx) p3.1

INT_EX0			bit		p3.2			;J7 CON1 p3.2 ?

INT_EX1			bit		p3.3			;J8 CON2 p3.3 ?

tir				bit		p3.4			;P3.4 (T1) TIR Interagir avec la carte maitre P3.5 T0  ?
		
;Varialbes utilises
tour			equ		R1
message			equ		R2
tir_or_not		bit		b.0

;----------------------------------------------------------------------------------
;Au reset
				org		0000h
				ljmp	debut
				org		0023h
				ljmp	INT_Serial


;----------------------------------------------------------------------------------
;les sous programmes du LCD
		;A- 	"init_lcd"			Initialisation du lcd exeuter une seule fois
		;C-		"en_lcd_code"		Validation de l'envoi d'une instruction avec verification du BUSY FLAG
		;D-		"test_busy_lcd"		Attente de la reponse du LCD
		;E-		"en_lcd_data"		Envoi d'une donnee au LCD
		;F-		"ligne_1"			Ecriture sur la ligne 1 du LCD
		;G-		"ligne_2"			Ecriture sur la ligne 2 du LCD
		;H-   	textes à envoyer
		;I-   	"emi_car"			Emission d'un caracatere
		;J-   	"envoi_message" 	Envoi du message
		;K-   	temposisations
		;L-   	programme principal
;-------------------------------------------------------------------------------
				org		0030h
init_lcd:
				;nop
				mov		LCD,#00h
				
				;temporisation 4 x 50ms
				lcall	tempo_02s
				
				;3 fois	
				;Envoyer un code "0011 xxxx"h sans tester le busy flag
				mov		LCD,#38h
				lcall 	en_lcd_code_init  ;appel au sous programme de validation d'une commande sans Busy Flag
				lcall	tempo_50ms 	;temporisation 50ms
				mov		LCD,#38h
				lcall 	en_lcd_code_init  ;appel au sous programme de validation d'une commande sans Busy Flag
				lcall	tempo_50ms 	;temporisation 50ms
				mov		LCD,#38h
				lcall 	en_lcd_code_init  ;appel au sous programme de validation d'une commande sans Busy Flag
				lcall	tempo_50ms 	;temporisation 50ms
				
				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

				mov		lcd,#01h			;efface affichage remet compteur à 0
				lcall	en_lcd_code		;appel au sous programme de validation d'une commande
				lcall	tempo_50ms		;temporisation 50ms
				mov		lcd,#0Ch			;allumage de l'afficheur
				lcall	en_lcd_code		;appel au sous programme de validation d'une commande
				lcall	tempo_50ms 		;temporisation 50ms
				mov		lcd,#06h			;incremente le curseur
				lcall	en_lcd_code		;appel au sous programme de validation d'une commande
				lcall	tempo_50ms		;temporisation 50ms
				mov		lcd,#38h			;affiche sur 2 lignes en 5x8 points
				lcall	en_lcd_code		;appel au sous programme de validation d'une commande
				lcall	tempo_50ms		;temporisation 50ms

				ret
;----------------------------------------------------------------------------------------------
;envoi d'une instruction sans tester le busy flag
en_lcd_code_init:
				clr		RS
				clr		RW
				setb	E
				clr		E
				ret       

;----------------------------------------------------------------------------------------------
;validation de l'envoi d'une instruction avec verification de l'etat du BUSY FLAG
en_lcd_code:								;sous programme de validation d'une instruction 
				clr		RS
				clr		RW
				setb	E
				clr		E
				lcall	test_busy_lcd
				ret
				

;-----------------------------------------------------------------------------------------------
;test du busy flag pour envoi d'autres instructions ou donnees
test_busy_lcd:								;test de la valeur du BUSY FLAG renvoyé sur DB7 par le LCD	
				mov		lcd,#0ffh			
				clr		RS
				setb	RW
				setb	E
attend_busy:
				jb		busy,attend_busy
            	clr		E
				ret
;--------------------------------------------------------------------------------------------------	
;validation de l'envoi d'un caractère avec verification de l'etat du BUSY FLAG
en_lcd_data:
				setb	RS
				clr		RW
				setb	E
				clr		E
				lcall	test_busy_lcd
				ret
				
;----------------------------------------------------------------------------------------------------
;écriture du texte sur la ligne premiere ligne du lcd
ligne_1:
				mov		LCD,#01h
				lcall	en_lcd_code
				mov		LCD,#80h
				lcall	en_lcd_code
				ret
				

;-----------------------------------------------------------------------------------------------------
;écriture du texte sur la seconde ligne du LCD
ligne_2:
				mov		LCD,#0C0h
				lcall	en_lcd_code
				ret

;-----------------------------------------------------------------------------------------------------				
;4 les textes à envoyer
				org		00F0h
texte1:
				DB		'****EQUIPE 2****'
				DB		0
				DB		'***EN ATTENTE***'
				DB		0
;texte2:
;				DB		'****TOUR '
;				DB		0
;				DB		'******'
;				DB		0
;				DB		'****GO!GO!GO!***'
;				DB		0
texte3:
				DB		'****TOUR '
				DB		0
				DB		'******'
				DB		0
				DB		'***MESSAGE:'
				DB		0
				DB		'****'
				DB		0

;-----------------------------------------------------------------------------------------------------
;5 vos sous programmes
				org		0180h
;-----------------------------------------------------------------------------------------------------
;5-a  emission de caracteres ASCII
emi_car:		
				clr		a
				movc	a,@a+dptr
				jz		sortie
				mov		lcd,a
				lcall	en_lcd_data
				lcall	tempo_50ms		;temporisation 50ms
				inc		dptr
				sjmp	emi_car
sortie:
				ret
;-----------------------------------------------------------------------------------------------------
;5-b	sous-programme d'envoi de message*
envoi_message:						;sauvegarder Acc avant l'appel de la fonction
				lcall	ligne_1
				lcall	emi_car
				inc		dptr                                                                                                                                                                                                                                                                                 
				lcall	ligne_2
				lcall	emi_car
            	ret

envoi_message2:						;sauvegarder Acc avant l'appel de la fonction
				lcall	ligne_1
				lcall	emi_car
				mov		lcd,tour
				lcall	en_lcd_data
				lcall	tempo_50ms		;temporisation 50ms
				inc		dptr
				lcall	emi_car
				inc		dptr                                                                                                                                                                                                                                                                                 
				lcall	ligne_2
				lcall	emi_car
            	ret

envoi_message3:						;sauvegarder Acc avant l'appel de la fonction
				lcall	ligne_1
				lcall	emi_car
				mov		lcd,tour
				lcall	en_lcd_data
				lcall	tempo_50ms		;temporisation 50ms
				inc		dptr
				lcall	emi_car
				inc		dptr                                                                                                                                                                                                                                                                                 
				lcall	ligne_2
				lcall	emi_car
				mov		lcd,message
				lcall	en_lcd_data
				lcall	tempo_50ms		;temporisation 50ms
				inc		dptr
				lcall	emi_car
            	ret

;-----------------------------------------------------------------------------------------------------
;tempo de 2s
tempo_2s:
				mov		r7,#40
attente2:
				lcall	tempo_50ms		;temporisation 50ms
				djnz	r7,attente2
				ret

;tempo_2s:		mov R7,#20
;attente21:   	mov R6,#200
;attente22:   	mov R5,#250
;      			DJNZ R5,$
;      			DJNZ R6,attente22
;      			DJNZ R7,attente21
;      			RET
				
;-----------------------------------
;tempo de 0,2s
tempo_02s:
				mov		r7,#4
attente02:
				lcall	tempo_50ms		;temporisation 50ms
				djnz	r7,attente02
				ret

;tempo_02s:		mov R7,#2
;attente021:   	mov R6,#200
;attente022:   	mov R5,#250
;      			DJNZ R5,$
;      			DJNZ R6,attente022
;      			DJNZ R7,attente021
;      			RET

;----------------------------------------------------------------------------------
;tempo de 50ms
;tempo_50ms:
				;mov		tmod,#21h
;				clr		tr0
;				clr		tf0
;				mov		th0,#3Ch
;				mov		tl0,#0B6h
;				setb	tr0
;rep_50:			jnb		tf0,rep_50
;jsq_50:			clr		tr0
;				clr		tf0
;				ret

tempo_50ms:		
attente501:   	mov R6,#100
attente502:   	mov R5,#250
      			DJNZ R5,$
      			DJNZ R6,attente502
      			RET

;-----------------------------------------------------------------------------------------------------
;programme principal
				org		0220h

INT_Serial:		
				push	Acc
				mov		A,SBUF
				clr		RI
				
				;si "0" est recu, GO!
recu_0:			
				cjne	A,#30h,recu_4
				clr		P1.2				;initialisation
				clr		P1.3
				clr		tir_or_not
				mov		message,#30h
				clr		ES					;Arreter le mode Interruption
				
				cjne	tour,#33h,continue_0
				setb	TB8					;Envoyer le message "1" pour Arreter la voiture
				mov		SBUF,#031h
att_env2:		jnb		ti,att_env2			;Attendre l'envoi de messaage
				clr		ti
				ljmp	fin_int_serial

continue_0:				
				setb	TB8					;Envoyer le message "0" pour declencher la voiture
				mov		SBUF,#030h
att_env:		jnb		ti,att_env			;Attendre l'envoi de messaage
				clr		ti
				cpl		f0					;Mettre le drapeau a 1 pour changer l'affichage	
				inc		tour 				;Increment le numero de tours
				lcall	tempo_02s
				setb	ES
				ljmp	fin_int_serial

				;si "4" est recu
recu_4:
				cjne	A,#34h,recu_d 		;si tir_or_not = 0, laser&sirene; sinon j'ignore
				jb		tir_or_not,fin_int_serial
				setb	P1.2
				setb	P1.3
				setb	tir_or_not
				ljmp	fin_int_serial

				;si "D" est recu
recu_d:
				cjne	A,#44h,recu_c
				mov		message,#44h
				ljmp	fin_int_serial
				
				;si "C" est recu
recu_c:			
				cjne	A,#43h,recu_g
				mov		message,#43h
				ljmp	fin_int_serial
									
				;si "G" est recu
recu_g:
				cjne	A,#47h,fin_int_serial
				mov		message,#47h
				clr		P1.2
				clr		P1.3
				ljmp	fin_int_serial

fin_int_serial:	
				pop		Acc
				reti

debut:
 				;Initialisation
				mov		tour,#30h
				mov		b,#0
				clr		P1.2			
				clr		P1.3
				;Initialisation de LCD
 				lcall	tempo_02s		;temporisation 0.2s
				lcall	init_lcd

				;Initialisation de Serial
				mov		scon,#0D0h
				mov		tmod,#21h		;Mode 2 de Timer1 pour la com Serial
				mov		th1,#0E6h
				mov		tl1,#0E6h		;Baud = 1200
				setb	es
				setb	ea
				setb	tr1

boucle_att:
				mov		dptr,#texte1
				lcall	envoi_message
				lcall	tempo_2s		;temporisation 2s
				jnb		f0,boucle_att
				
								

;boucle_exec:	mov		dptr,#texte2
;				lcall	envoi_message2
;				lcall	tempo_50ms
;				ljmp	boucle_exec


boucle_laser:	mov		dptr,#texte3
				lcall	envoi_message3
				lcall	tempo_2s
				ljmp	boucle_laser
					

fin:
;-----------------------------------------------------------------------------------------------------
;fin de compilation
				end 
