bumper_pres_x_pos dw 160-24
bumper_pres_y_pos dw 80
bumper_pres_x_vel dw 0
bumper_pres_x_vel_max db 8
bumper_pres_speed dw 3
bumper_pres_facing_left db 0 ; visual
bumper_pres_moving_left db 0 ; movement
bumper_pres_gfx: incbin "bumper_pres.gfx"
smoke_puff_gfx: incbin "smoke_puff_small.gfx"
smoke_puff_x_pos dw 0
smoke_puff_y_pos dw 0
smoke_puff_x_vel dw 0
smoke_puff_visible db 0
smoke_puff_moving_left db 0
	
bumper_pres_draw:
	mov byte [bgl_opaque],0
	mov al,[bumper_pres_facing_left]
	mov byte [bgl_flip],al
	mov byte [bgl_erase],0
	mov ax,bumper_pres_gfx
	mov word [bgl_buffer_offset],ax
	mov ax,[bumper_pres_x_pos]
	mov word [bgl_x_pos],ax
	mov ax,[bumper_pres_y_pos]
	mov word [bgl_y_pos],ax
	call bgl_draw_gfx
	
	; smoke puff
	cmp byte [smoke_puff_visible],0 ; is it visible?
	je .skip ; if not, skip
	mov byte [bgl_opaque],0
	mov byte [bgl_flip],0
	mov byte [bgl_erase],0
	mov ax,smoke_puff_gfx
	mov word [bgl_buffer_offset],ax
	mov ax,[smoke_puff_x_pos]
	mov word [bgl_x_pos],ax
	mov ax,[smoke_puff_y_pos]
	mov word [bgl_y_pos],ax
	call bgl_draw_gfx
	
.skip:
	ret

bumper_pres_movement:
	xor ax,ax
	mov al,[bumper_pres_x_vel_max]
	cmp word [bumper_pres_x_vel],ax ; first check that the x vel is valid
	jle .smoke_puff ; if it is valid, skip
	mov word [bumper_pres_x_vel],ax ; if not, MAKE IT.
	
	cmp byte [smoke_puff_visible],0 ; smoke puff visible?
	je .smoke_puff ; if not, skip
	
.smoke_puff:
	mov ax,[smoke_puff_x_vel]
	cmp byte [smoke_puff_moving_left],0 ; smoke puff moving left?
	je .smoke_puff_move_right ; if not, skip
	sub word [smoke_puff_x_pos],ax
	jmp .smoke_puff_move_skip
.smoke_puff_move_right:
	add word [smoke_puff_x_pos],ax
.smoke_puff_move_skip:
	sub word [smoke_puff_y_pos],2
	cmp word [smoke_puff_y_pos],-32 ; reached top of screen?
	jg .move_right ; if not, skip
	mov byte [smoke_puff_visible],0
	jmp .move_right
	
	mov ax,[bumper_pres_x_vel]
	cmp byte [bumper_pres_moving_left],0 ; am i moving left?
	jne .smoke_puff_move_skip2 ; if not, skip
	sub word [smoke_puff_x_pos],ax
	jmp .move_right
.smoke_puff_move_skip2:
	add word [smoke_puff_x_pos],ax

.move_right:
	cmp byte [bumper_pres_moving_left],0 ; facing left?
	je .move_left ; if so, move left
	xor ax,ax
	mov ax,[bumper_pres_x_vel] ; otherwise, move... right
	add word [background_arrow_x],ax
	shr ax,1
	add word [background_x],ax
	jmp .key_check_down
	
.move_left:
	xor ax,ax
	mov ax,[bumper_pres_x_vel]
	sub word [background_arrow_x],ax
	shr ax,1
	sub word [background_x],ax

	; detect key presses
	
.key_check_down:
	cmp word [bgl_key_states+50h],0 ; down pressed?
	je .key_check_up ; if not, skip
	cmp word [bumper_pres_y_pos],200-32 ; reached the bottom of the screen?
	jg .key_check_up ; if so, skip
	mov ax,[bumper_pres_speed]
	add word [bumper_pres_y_pos],ax

.key_check_up:
	cmp word [bgl_key_states+48h],0 ; up pressed?
	je .key_check_left ; if not, skip
	cmp word [bumper_pres_y_pos],48 ; reached the top of the screen?
	jl .key_check_left ; if so, skip
	mov ax,[bumper_pres_speed]
	sub word [bumper_pres_y_pos],ax

.key_check_left:
	cmp word [bgl_key_states+4bh],0 ; left pressed?
	je .key_check_right ; if not, skip
	
	cmp byte [bumper_pres_facing_left],0 ; facing left?
	jne .key_check_left_skip ; if not, skip
	call smoke_puff_appear
	shr word [bumper_pres_x_vel],3
	
.key_check_left_skip:
	mov byte [bumper_pres_facing_left],1
	mov byte [bumper_pres_moving_left],1
	inc word [bumper_pres_x_vel]
	jmp .key_check_end ; done checking for the left and right

.key_check_right:
	cmp word [bgl_key_states+4dh],0 ; right pressed?
	je .key_check_neither ; if not, skip
	
	cmp byte [bumper_pres_facing_left],0 ; facing left?
	je .key_check_right_skip ; if not, skip
	call smoke_puff_appear
	shr word [bumper_pres_x_vel],3
	
.key_check_right_skip:
	
	mov byte [bumper_pres_facing_left],0
	mov byte [bumper_pres_moving_left],0
	inc word [bumper_pres_x_vel]
	jmp .key_check_end ; done checking for the left and right
	
.key_check_neither: ; if neither left or right is pressed, decrease the x vel until reaches 0
	cmp word [bumper_pres_x_vel],0
	je .key_check_end
	dec word [bumper_pres_x_vel]
	
.key_check_end:
	ret
	
smoke_puff_appear:
	mov al,[bumper_pres_x_vel_max]
	shr al,2
	cmp byte [bumper_pres_x_vel],al ; has my x vel reached the max?
	jle .skip2 ; if not, skip
	
	cmp byte [smoke_puff_visible],0 ; smoke puff visible?
	jne .skip2 ; if so, skip
	
	mov al,[bumper_pres_moving_left]
	mov byte [smoke_puff_moving_left],al
	
	mov ax,[bumper_pres_x_vel]
	mov word [smoke_puff_x_vel],ax
	
	mov ax,[bumper_pres_x_pos]
	sub ax,12
	cmp byte [bumper_pres_facing_left],0 ; am i facing left?
	jne .skip ; if not, skip
	add ax,62
.skip:
	mov word [smoke_puff_x_pos],ax
	mov ax,[bumper_pres_y_pos]
	mov word [smoke_puff_y_pos],ax
	mov byte [smoke_puff_visible],1
.skip2:
	ret