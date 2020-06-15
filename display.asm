    NAME    DISPLAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   DISPLAY                                  ;
;                               Display Functions                            ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; These procedures are the display routines needed in order to output a hexadecimal 
; or decimal string to a 7 segment LED display. The procedures included in this file are:
;		DisplayInit - This procedure sets up for the display procedure by initializing the
;					  the muxing index and filling the muxing buffer with 0s.
;		Display - Thus procedure converts the strings in the string buffer (or a string 
;				  passed to the function in ES:SI) to the segment pattern and stores them
;				  in another buffer that will be used by the multiplexing function to 
;				  output the string to the LED display. 
;		DisplayNum - This procedure calls the Dec2String function to convert a number
;					 to a decimal string and stores it in a buffer starting at DS:SI.
;					 It then moves this buffer to ES, so that it can be used in the
;					 display function.
;		DisplayHex - This procedure does the same as DisplayNum, except it call Hex2String
;					 and converts a number to hexadecimal to be displayed on the LED
;					 display.
;		LEDMux - This procedure gets the next digit in the buffer containing the segment
;				 pattern conversions and outputs it to the display. 

; Revision History: 11/8/14		Mugdha Walke		Initial coding
;					11/9/14		Mugdha Walke		Finished coding

$INCLUDE(display.inc) 

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
; External Function Declarations

        EXTRN      Dec2String:NEAR
        EXTRN      Hex2String:NEAR
        EXTRN      ASCIISegTable:BYTE
        

; DisplayInit
;
; Description: This function initializes the display function by initializing the muxing
;			   index and filling the muxing buffer (the buffer containing the segment
;			   pattern conversions) with 0s.     
;
; Operation: The muxing index will be set to 0. Additionally, the procedure will loop
;			 through the muxing buffer and fill it with 0s.    
; Arguments: none      
;
; Local Variables: none 
; Shared Variables: MuxingBuffer - will hold the segment patterns for the ASCII strings to
;								be displayed
;					MuxIndex - Index for the mux buffer
; Global Variables: none
;
; Input: none
; Output: none
;
; Error Handling:   none
;
; Algorithms:       none
; Data Structures:  none
;
; Registers Changed: none     
;
; Author:           Mugdha Walke
; Last Modified:    11/9/14


DisplayInit     PROC        NEAR
                PUBLIC      DisplayInit
                
PUSHA

    MOV     DS:MuxIndex, 0      ;Initializes the MuxIndex
    MOV     BX, 0               ;Makes BX into a pointer

DisplayInitStart:
    
    CMP     BX, MBUFFER_SIZE       ;Checks if the index is at the end of the buffer
    JE      DisplayInitEnd         ;If yes, then will end the procedure
    ;JMP    ClearBuffer            ;If not, will fill the muxbuffer with 0s
    
ClearBuffer:

    MOV     DS:MuxingBuffer[BX], 0  ;Fills the MuxingBuffer with 0
    INC     BX                   	;Prepares to move to the next location in the buffer
    JMP     DisplayInitStart
    
DisplayInitEnd:

    POPA
    RET
    
DisplayInit     ENDP

    


; Display (str)
;
; Description: This function is passed a <null> terminated string to output to
;              the LED display. A string can either by directly passed to the function,
;			   or it can come from DisplayNum or DisplayHex. This procedure will convert 
;			   the strings to their respective segment patterns so that they can be output
;			   to the LED display, by storing them in a muxing buffer. If there is a 
;			   string longer than 8 'digits', it will be cut off at 8. If the string is 
;			   smaller, the rest of the buffer will be filled with 0s.      
;
; Operation:   The function loops through the string buffer containing the string
;			   characters and converts them to their respective segment patterns, and then
;			   stores the segment pattern into another buffer, the muxing buffer. To get
;			   the segment pattern for each string, XLAT is used on a pre-declared 
;			   7 segment conversion table. 
;               
; Arguments:   str - string character to be displayed passed by reference in ES:SI.
; Return Values: none      
;
; Local Variables:  none
; Shared Variables: MuxingBuffer - The buffer array where the segment pattern - converted
;					strings will be stored. 
; Global Variables: none
;
; Input: none
; Output: none
;
; Error Handling:   none
;
; Algorithms:       none
; Data Structures:  none
;
; Registers Changed: none   
;
; Author:           Mugdha Walke
; Last Modified:    11/9/14
;
; Display Pseudo Code


Display     PROC        NEAR
            PUBLIC      Display 
            
PUSHA
    XOR     DI, DI                  ;Let DI be the index, clear it
CheckMuxIndex:

    CMP     DI, MBUFFER_SIZE        ;Checks if the index is at the end of buffer                      
    JE      EndDisplay              ;If yes, will not display past the array
    ;JMP    CheckString             ;If not, will check to see if string is at null
    
CheckString:

    MOV     AL, ES:[SI]				;Prepares to check if the string is null
    CMP     AL, 0                   ;Checks if the string at the buffer is null
    JE      FillZero                ;If yes, will fill the rest of the buffer with zeros
    ;JMP    ConvertSegment          ;If not, will store segment pattern of string in 
									;	muxing buffer

ConvertSegment:

    LEA     BX, ASCIISegTable		   ;Prepares the ASCIItable to be used for conversion
    XLAT    CS:ASCIISegTable           ;Puts the segment pattern of the string in AL
    MOV     MuxingBuffer[DI], AL	  ;Value at muxbuffer now contains the segment pattern
    INC     DI                         ;Will move to the next location in the muxingbuffer
    INC     SI                         ;Will move to the next location in the string
    JMP     CheckMuxIndex              ;Loop back to fill in the rest of the muxing buffer
    
FillZero:

    MOV     MuxingBuffer[DI], 0        ;Fills the open spots in the buffer with a 0
    INC     DI                         ;Increments the muxindex
    CMP     DI, MBUFFER_SIZE       	   ;Checks if the index is at the end of the buffer
    JE      EndDisplay                 ;If so, then do not display anymore
    JMP     FillZero                   ;Will loop through this section, writing all the 
									   ;	zeros the remaining spots
    
EndDisplay:
    POPA
    RET                                ;ends the procedure
    
Display      ENDP
    
    
    
    



; DisplayNum (n)
;
; Description: This function takes a 16 bit signed value and converts it
;              to a null terminated decimal string (at most 5 digits plus sign) 
;              and stores it in a string buffer at starting address DS:SI. It will then 
;			   move the buffer into ES. 
;
; Operation:   This function calls the Dec2String function to convert the 
;              16 bit signed value, and will store it in a buffer array, and move the 
;			   array to ES.
; Arguments:   n - the 16 bit value to be converted to decimal, is passed
;                  in AX by value.
; Return Values: none      
;
; Local Variables: AX - will hold the number to be converted.   
; Shared Variables: strbuffer
; Global Variables: none
;
; Input: none
; Output: none
;
; Error Handling:   none
;
; Algorithms:       none
; Data Structures:  none
;
; Registers Changed: none  
;
; Author:           Mugdha Walke
; Last Modified:    11/9/14
;

DisplayNum      PROC        NEAR
                PUBLIC      DisplayNum

                
    LEA     SI, strbuffer       ;Sets the strbuffer starting address at SI
    CALL    Dec2String          ;Converts the number to a decimal string and stores it in 
                                ;  the string buffer
    MOV     AX, DS				;prepares to move DS into ES
    MOV     ES, AX              ;moves the buffer into ES
    CALL    Display				;Get segment pattern array for string array
                
    RET
                
DisplayNum      ENDP
            


; DisplayHex (n)
;
; Description: TThis function takes a 16 bit unsigned value and converts it
;              to a null terminated hexadecimal string (4 digits) 
;              and stores it in a string buffer at starting address DS:SI. It will then 
;			   move the buffer into ES.    
;
; Operation:   This function calls the Hex2String function to convert the 
;              16 bit value to hexadecimal and will store the strings in an array at 
;			   the starting address SI. 
; Arguments: n - the 16 bit value to be converted to hexadecimal, will be passed
;                in AX by value.
; Return Values: none        
;
; Local Variables: AX - will hold the number to be converted
; Shared Variables: strbuffer
; Global Variables: none
;
; Input: none
; Output: none
;
; Error Handling:   none
;
; Algorithms:       none
; Data Structures:  none
;
; Registers Changed: none
 
;
; Author:           Mugdha Walke
; Last Modified:    11/9/14
;

DisplayHex      PROC        NEAR
                PUBLIC      DisplayHex
               
               
    LEA     SI, strbuffer           ;Sets the strbuffer starting address to SI
    CALL    Hex2String              ;Converts the number to hexadecimal that will be 
									;	stored starting at the strbuffer
    MOV     AX, DS
    MOV     ES, AX                  ;Moves the buffer to ES
    CALL    Display
  
    RET
           
            
DisplayHex      ENDP


; LEDMux 
;
; Description: This function multiplexes the digits in the display
;              under interrupt control every 1 ms. 
;
; Operation: This function outputs the next string character in the muxbuffer to the LED
;			 display. It will start the mux index at the start of the buffer array and
;			 increase by one each time its called, and output to the display. If the index
;			 reaches the end of the array, it will wrap around to the beginning by being
;			 set to 0. 
; Arguments: none       
;
; Local Variables: BX - temporary index in place of muxindex
; Shared Variables: MuxIndex, MuxingBuffer
; Global Variables: none
;
; Input: none
; Output: The next segment is output to the display
;
; Error Handling:   none
;
; Algorithms:       none
; Data Structures:  none
;
; Registers Changed: none
;
; Author:           Mugdha Walke
; Last Modified:    11/9/14
;

LedMUX      PROC        NEAR
            PUBLIC      LedMUX

PUSHA

    MOV     BX, MuxIndex    
LedMuxSetup:
    
	CMP		BX, MBUFFER_SIZE		  ;Checks if the index is at the end, if so will
									  ;		need to reset to 0. 
    JE      ResetIndex    			  ;If it its equal to 8, then it will reset the index
    JMP     DisplayNextDigit          ;else, go on to display the next digit
    
ResetIndex:

    MOV     BX, 0					;Resets the muxindex to the start of the buffer again
    ;JMP    DisplayNextDigit        ;Will display the next digit
   
DisplayNextDigit:

    MOV     DX, 0000H				;Stores address of first display location
                                    ;Prepares the address that is to be output to             
    ADD     DX, BX                  ;Goes to correct location on display
    MOV     AL, MuxingBuffer[BX]    ;Prepares for outputting the value at muxindex
    OUT     DX, AL                  ;Outputs the segment pattern of the char to display
	INC 	BX						;Increments the index for the next call									
    ;JMP    EndMux

EndMux:
    MOV     MuxIndex, BX			;Updates the muxindex
    POPA
    RET
    
LedMux      ENDP

CODE ENDS



;Declarations for the shared variables, the multiplexing index, the multiplexing buffer
;and the string buffer
DATA        SEGMENT PUBLIC  'DATA'

        StrBuffer       DB      8       DUP (?)
        MuxingBuffer    DB      8       DUP (?)
        MuxIndex        DW      ?

DATA ENDS
        
    END