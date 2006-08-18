; MOD player  (c) 2002 mls
;
; generates samples for 11000 HZ
; bpm always 125

STATE_OFF	equ 0
STATE_PLAY	equ 1
STATE_SAMPLE	equ 2

; struct volume
vo_volume	equ 0
vo_volumegoal	equ vo_volume + 2
vo_volumerate	equ vo_volumegoal + 2
vo_sizeof	equ vo_volumerate + 2

; struct channel
ch_samp		equ 0
ch_startseg	equ ch_samp + 2
ch_pitch	equ ch_startseg + 2
ch_finetune	equ ch_pitch + 2
ch_volume	equ ch_finetune + 2

ch_start	equ ch_volume + 2
ch_pointer	equ ch_start + 2
ch_pointer8	equ ch_pointer + 2
ch_end		equ ch_pointer8 + 2
ch_send		equ ch_end + 2
ch_roff		equ ch_send + 2
ch_rend		equ ch_roff + 2
ch_step		equ ch_rend + 2
ch_step8	equ ch_step + 2

ch_slide	equ ch_step8 + 2
ch_vibrate	equ ch_slide + 2
ch_viboffset	equ ch_vibrate + 2
ch_vibdepth	equ ch_viboffset + 2
ch_pitchgoal	equ ch_vibdepth + 2
ch_pitchrate	equ ch_pitchgoal + 2
ch_volumerate	equ ch_pitchrate + 2
ch_arpindex	equ ch_volumerate + 2
ch_arp		equ ch_arpindex + 2
ch_current	equ ch_arp + 3 * 2
ch_retrig	equ ch_current + 2
ch_latesamp	equ ch_retrig + 2
ch_effect	equ ch_latesamp + 2
ch_player	equ ch_effect + 2
ch_sizeof       equ ch_player + 2

; struct player
pl_volume	equ 0
pl_state	equ pl_volume + vo_sizeof
pl_songlen	equ pl_state + 2
pl_speed	equ pl_songlen + 2
pl_effpos	equ pl_speed + 2
pl_nextsongnum	equ pl_effpos + 2
pl_nextnotenum	equ pl_nextsongnum + 2
pl_songnum	equ pl_nextnotenum + 2
pl_notenum	equ pl_songnum + 2
pl_loop_notenum	equ pl_notenum + 2
pl_loop_counter	equ pl_loop_notenum + 2
pl_seg		equ pl_loop_counter + 2
pl_song		equ pl_seg + 2
pl_patterns     equ pl_song + 4
pl_sampinfo     equ pl_patterns + 4
pl_sampd        equ pl_sampinfo + 4
pl_sampdseg     equ pl_sampd + 2 * 32
pl_channs       equ pl_sampdseg + 4 * 32
pl_loaded	equ pl_channs + 4 * ch_sizeof
pl_sizeof	equ pl_loaded + 2

EFF_ARP		equ 1
EFF_SLIDE	equ 2
EFF_PORTA	equ 3
EFF_VIBRA	equ 4
EFF_RETRIG	equ 5
EFF_CUT		equ 6
EFF_LATESTART	equ 7
EFF_SLIDEVOL	equ 8
EFF_PORTASLIDE	equ 8 + 3
EFF_VIBRASLIDE	equ 8 + 4

		; _must_ be 320
num_samples	equ 320

; struct area
ar_hassamp	equ 0
ar_samps	equ ar_hassamp + 1
ar_volume	equ ar_samps + num_samples + 1
ar_players	equ ar_volume + vo_sizeof
ar_ssamps	equ ar_players + pl_sizeof * 4
ar_sizeof	equ ar_ssamps + num_samples * 2

