NAME        KEYPAD 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   KEYPAD                                   ;
;                               Keypad Routines                              ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This file contains the keypad functions. These functions register a single key
; press on a 4 by 4 keypad by enqueue-ing the key press in an event buffer that
; holds the event constant (chosen to be 1 in this case) followed by the key
; value. The functions in this file are:
;  InitKeypad:      initalizes the variables needed to scan and debounce, namely
;                   the current row, current key value, and the debounce counter
;  ScanAndDebounce: scans the keypad 1 row each time it is called for a key
;                   press. If a key is pressed, it will check if the key
;                   as been pressed for a set debounce time (50 ms) before
;                   the press is enqueued as an event. 

; Revision History:
;           11/10/14        Mugdha Walke        initial comments
;           11/16/14        Mugdha Walke        coding

$INCLUDE (keypad.inc)   ;include file which contains constants for the functions

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA


CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
        
; External function declarations
    
    EXTRN   EnqueueEvent:NEAR           ;Used to enqueue the key press into an
                                        ;   event buffer

;InitKeypad

; Description: This procedure initializes values needed for the scan and
;              debounce procedure. The variables that are initialized are 
;              the current row (cur_row), the current key value (cur_key), and
;              the debounce counter (debounce_ctr). The current row is set at
;              the address of the first row in the keypad, 80H which is the
;              BASE_ADDR. cur_key is set to 0F, or HIGH_MASK which is the value
;              when no key is pressed. debounc_ctr is set to MAX_TIME, which is
;              the time that the key needs to be pressed down for in order for 
;              it to be enqueued. 
;
; Operation:   cur_row is set to BASE_ADDR, cur_key is set to HIGH_MASK, and
;              debounce_ctr is set to MAX_TIME.  
;              
;               
; Arguments: none  
; Return Values: none      
;
; Local Variables:  none
; Shared Variables: debouncecntr - written: set to the debounce time
;                   cur_row - written: set to the address of the first row
;                   cur_key - written: set to no key pressed (0F) 
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
; Known Bugs: none
; Limitations: none
; Special Notes: none      
;
; Author:           Mugdha Walke
; Last Modified:    11/16/14
;

InitKeypad      PROC        NEAR
                PUBLIC      InitKeypad
                
        MOV     cur_row, BASE_ADDR      ; Makes the current address equal to the
                                        ;   address of the first row
        MOV     cur_key, HIGH_MASK      ; Sets the key value to no press
        MOV     debounce_ctr, MAX_TIME  ; Sets the debounce counter to max time
        
        RET

InitKeypad      ENDP
        
                


;ScanAndDebounce
;
; Description: This function will be called once every ms by an event handler.
;              Everytime it is called, it will scan the current row to see if 
;              a key is pressed, that is, having a value of either 0e, 0d, 0b,
;              of 0f. If so, the function will decrement the debounce counter.
;              If the key is pressed for the length of the debounce time (set
;              to be 50 ms), then it will be counted as a key press and will 
;              be enqueued into the event buffer as an event.
; Operation:   Each time the event handler calls this function, the current row
;              is checked for a key press. If there is no key press, the 
;              function will move onto the next row (wrapping back to the 
;              beginning if it is as the last row) and wait to be called again.
;              If a key is pressed, the key press will be debounced, meaning
;              that a debounce counter will decrement each time the function is
;              called for the duration of the debounce time(which is set to 
;              50 ms). If the key has been pressed for this long, the key press
;              will be enqueued into an event buffer with a key event constant
;              followed by the key value.  
;               
; Arguments:   none
; Return Values: none      
;
; Local Variables:  none
; Shared Variables: none
; Global Variables: none
;
; Input: keypad row address
; Output: none
;
; Error Handling:   none
;
; Algorithms:       none
; Data Structures:  none
;
; Registers Changed:  none     
; Known Bugs: none
; Limitations: none
; Special Notes: none

; Author:           Mugdha Walke
; Last Modified:    11/16/14



ScanAndDebounce        PROC        NEAR
                       PUBLIC      ScanAndDebounce
                
GetKey:

        PUSHA
        MOV     DX, 0             ; Clears DX for use
        MOV     DX, cur_row       ; Inputs the keyvalue from the
                                  ;   current keypad row
        IN      AL, DX            ; The current keyvalue is now in AL                 
        AND     AL, HIGH_MASK     ; The lower 4 bits of the keyvalue are now
                                  ;     stored in AL                                   
        CMP     AL, HIGH_MASK     ; If a key is not being pressed
        JE      NextRow           ; Then go to the next row

        CMP     AX, 0EH              ;Check if the key is in the first column
        JE      Column1              ;If so, move 1 into AX
        CMP     AX, 0DH              ;Check if the key is in the 2nd column
        JE      Column2              ;If so, move 2 into AX
        CMP     AX, 0BH              ;Check if the key is in the 3rd column
        JE      Column3              ;If so, move 3 into AX
        CMP     AX, 07H              ;Check if the key is in the 4th column
        JE      Column4              ;If so, then move 4 into AX
        
Column1:

        MOV     AX, 0               ;AX now represents column 1
        JMP     CheckDebounce       ;Jump to check if the key should be debounced
        
Column2:

        MOV     AX, 1               ;AX now represents column 2
        JMP     CheckDebounce       ;Jump to check if the key should be debounced
        
Column3:

        MOV     AX, 2
        JMP     CheckDebounce
        
Column4:

        MOV     AX, 3
        JMP     CheckDebounce
       
CheckDebounce:
       
        MOV     CX, cur_row
        SAL     CX, NUM_ROWS       ; Gets the row number plus value and puts
                                   ;    it in AL
        MOV     AH, 0
        OR      AX, CX
        CMP     AL, cur_key             ; Check if the key pressed is the same
                                        ;    as before 
        JNE     RestartCount             ; Go to the end *
        DEC     debounce_ctr      ; Decrement the debounce counter to see if
                                  ; it is at 0. If so, will count as key press
        CMP     debounce_ctr, 0   ; Has the key been pressed for the entire 
                                  ;   debounce time?
        JZ      KeyDebounced      ; If so, will start the debounce counter
                                  ;  from the max time again and count the press
        JMP     EndDebounce       ; Otherwise, will wait for next call
        
NextRow:

        MOV     cur_key, HIGH_MASK
        INC     cur_row             ; If no key is pressed, go onto the next row
        CMP     cur_row, BASE_ADDR + NUM_ROWS  ; If the cur_row reaches the last 
                                               ;    one              
        JE      WrapRow                 ; Wrap back to the first row
        JMP     EndDebounce
        
WrapRow:


        MOV     cur_row, BASE_ADDR      ; Sets the cur_row to the first row
                                        ;   to begin again
        JMP     EndDebounce             ; Done until the next call                                        
                                    
RestartCount:

        MOV     cur_key, AL
        MOV     debounce_ctr, MAX_TIME  ; Restarts the debounce ctr
        JMP     EndDebounce 

       
KeyDebounced:
        
        MOV     cur_key, AL        
        MOV     AH, KEY_EVENT    
        
        CALL    EnqueueEvent            ; Registers the key press
        MOV     debounce_ctr, AUTO_REP  ; Restarts the debounce ctr
        JMP     EndDebounce 

        
EndDebounce: 
           
        POPA
        RET

ScanAndDebounce     ENDP

CODE    ENDS


; Data segment, which is used to set up the shared variables. 

DATA        SEGMENT PUBLIC  'DATA'

        cur_row         DW             ?   ;current row of the keypad
        cur_key         DB             ?   ;current key value of the key pressed
        debounce_ctr    DW             ?   ;counter used to count down to the
                                           ;    debounce time. 

DATA ENDS

END