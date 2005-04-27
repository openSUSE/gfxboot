% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Install mode selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/install.last 0 def

/install.option 255 string def

% install types
/.inst_cdrom	0 def
/.inst_slp	1 def
/.inst_ftp	2 def
/.inst_http	3 def
/.inst_nfs	4 def
/.inst_smb	5 def
/.inst_hd	6 def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build install mode list.
%
% ( ) ==> ( )
%
/install.init {
  /xmenu.install .xm_size array def

  /xmenu xmenu.install def

  /install.last usernote 5 shr 1 and def

  install.option install.last .inst_cdrom eq { "" } { "install=slp" } ifelse strcpy

  xmenu .xm_current install.last put

  % see install types (.inst_*)
  xmenu .xm_list [ is_dvd { "DVD" } { "CD-ROM" } ifelse "SLP" "FTP" "HTTP" "NFS" "SMB / CIFS" ] put

  pmenu.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update install mode.
%
% ( ) ==> ( )
%
/install.update {
  /xmenu xmenu.install def

  xmenu .xm_current get dup .inst_cdrom eq exch .inst_slp eq or {
    /install.last xmenu .xm_current get def

    install.option install.last .inst_cdrom eq { "" } { "install=slp" } ifelse strcpy

    /window.action actRedrawPanel def

    pmenu.update
  } {
    install.dialog
  }
  ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show install menu.
%
% ( ) => ( )
%
/panel.install {
  "install_src" help.setcontext

  window.xmenu
  dup .xmenu xmenu.install put
  dup .xmenu.update /install.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.install.width {
  /xmenu xmenu.install def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.install.update {
  /xmenu xmenu.install def

  pmenu.panel.update
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


/install.dialog {

  /dia window.dialog def

  dia .text "" put

  xmenu .xm_current get

  dup .inst_hd eq {
    input.edit.hd .undef eq {
      /input.edit.hd [ 63 string 127 string ] def
    } if

    dia .title txt_harddisk_title put

    % Must all be of same size!
    dia .ed.list 2 array put
    dia .ed.buffer.list input.edit.hd put
    dia .ed.text.list [ txt_hd_diskdevice txt_directory ] put

  } if

  dup .inst_ftp eq {
    input.edit.ftp .undef eq {
      /input.edit.ftp [ 63 string 127 string 31 string 31 string ] def
    } if

    dia .title txt_ftp_title put

    % Must all be of same size!
    dia .ed.list 4 array put
    dia .ed.buffer.list input.edit.ftp put
    dia .ed.text.list [ txt_server txt_directory txt_user1 txt_password ] put

    dia .ed.font font.normal put
    dia .ed.pw_field 3 put

  } if

  dup .inst_http eq {
    input.edit.http .undef eq {
      /input.edit.http [ 63 string 127 string ] def
    } if

    dia .title txt_http_title put

    % Must all be of same size!
    dia .ed.list 2 array put
    dia .ed.buffer.list input.edit.http put
    dia .ed.text.list [ txt_server txt_directory ] put

  } if

  dup .inst_nfs eq {
    input.edit.nfs .undef eq {
      /input.edit.nfs [ 63 string 127 string ] def
    } if

    dia .title txt_nfs_title put

    % Must all be of same size!
    dia .ed.list 2 array put
    dia .ed.buffer.list input.edit.nfs put
    dia .ed.text.list [ txt_server txt_directory ] put

  } if

  dup .inst_smb eq {
    input.edit.smb .undef eq {
      /input.edit.smb [ 63 string 127 string 31 string 31 string 31 string ] def
    } if

    dia .title txt_smb_title put

    % Must all be of same size!
    dia .ed.list 5 array put
    dia .ed.buffer.list input.edit.smb put
    dia .ed.text.list [ txt_server txt_directory txt_domain txt_user2 txt_password ] put

    dia .ed.font font.normal put
    dia .ed.pw_field 4 put

  } if

  pop

  dia .ed.focus 0 put
  dia .ed.width 300 put

  dia .buttons [
    button.ok button.default actInstallOK actNoClose or button.setaction
    button.cancel button.notdefault actInstallCancel button.setaction
  ] put

  dia window.init
  dia window.show

} def



/install.ok {
  /xmenu xmenu.install def

  window.done

  /install.last xmenu .xm_current get def

  /window.action actRedrawPanel def

  pmenu.update

  xmenu .xm_current get

  dup .inst_hd eq {
    input.edit.hd
    dup 1 get dup 0 get '/' eq { 1 add } if
    exch 0 get dup 0 get '/' eq { 1 add } if
    "install=hd://%s/%s" install.option sprintf
  } if

  dup .inst_ftp eq {
    input.edit.ftp

    "install=ftp://" install.option sprintf

    % add user name & password
    dup 2 get "" ne {
      dup 2 get "%s" install.option dup length add sprintf
      dup 3 get "" ne {
        dup 3 get ":%s" install.option dup length add sprintf
      } if
      "@" install.option dup length add sprintf
    } if

    dup 1 get exch 0 get "%s/%s" install.option dup length add sprintf
  } if

  dup .inst_http eq {
    input.edit.http
    dup 1 get dup 0 get '/' eq { 1 add } if
    exch 0 get
    "install=http://%s/%s" install.option sprintf
  } if

  dup .inst_nfs eq {
    input.edit.nfs
    dup 1 get dup 0 get '/' eq { 1 add } if
    exch 0 get
    "install=nfs://%s/%s" install.option sprintf
  } if

  dup .inst_smb eq {
    input.edit.smb

    "install=smb://" install.option sprintf

    % add domain
    dup 2 get "" ne {
      dup 2 get "%s;" install.option dup length add sprintf
    } if

    % add user name & password
    dup 3 get "" ne {
      dup 3 get "%s" install.option dup length add sprintf
      dup 4 get "" ne {
        dup 4 get ":%s" install.option dup length add sprintf
      } if
      "@" install.option dup length add sprintf
    } if

    dup 1 get exch 0 get "%s/%s" install.option dup length add sprintf
  } if

  pop

} def


/install.cancel {
  /xmenu xmenu.install def

  xmenu .xm_current install.last put

%  /window.action actRedrawPanel def
%  pmenu.update
} def

