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
  xmenu .xm_list [ is_dvd { "DVD" } { "CD-ROM" } ifelse "SLP" "FTP" "HTTP" "NFS" "SMB" /txt_harddisk ] put

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

  xmenu .xm_current get

  dup .inst_hd eq {
    input.dialog.hd {
      /dia input.dialog.hd def
    } {
      /input.dialog.hd window.dialog def
      /dia input.dialog.hd def

      dia .dont_free 1 put

      dia .title txt_harddisk_title put
      dia .text "" put

      % Must all be of same size!
      dia .ed.list 2 array put
      dia .ed.buffer.list [ 63 string 127 string ] put
      dia .ed.text.list [ txt_hd_diskdevice txt_directory ] put

      dia .ed.focus 0 put
    } ifelse
  } if

  dup .inst_ftp eq {
    input.dialog.ftp {
      /dia input.dialog.ftp def
    } {
      /input.dialog.ftp window.dialog def
      /dia input.dialog.ftp def

      dia .dont_free 1 put

      dia .title txt_ftp_title put
      dia .text "" put

      % Must all be of same size!
      dia .ed.list 4 array put
      dia .ed.buffer.list [ 63 string 127 string 31 string 31 string ] put
      dia .ed.text.list [ txt_server txt_directory txt_user1 txt_password ] put

      dia .ed.font font.normal put
      dia .ed.pw_field 3 put

      dia .ed.focus 0 put
    } ifelse
  } if

  dup .inst_http eq {
    input.dialog.http {
      /dia input.dialog.http def
    } {
      /input.dialog.http window.dialog def
      /dia input.dialog.http def

      dia .dont_free 1 put

      dia .title txt_http_title put
      dia .text "" put

      % Must all be of same size!
      dia .ed.list 2 array put
      dia .ed.buffer.list [ 63 string 127 string ] put
      dia .ed.text.list [ txt_server txt_directory ] put

      dia .ed.focus 0 put
    } ifelse
  } if

  dup .inst_nfs eq {
    input.dialog.nfs {
      /dia input.dialog.nfs def
    } {
      /input.dialog.nfs window.dialog def
      /dia input.dialog.nfs def

      dia .dont_free 1 put

      dia .title txt_nfs_title put
      dia .text "" put

      % Must all be of same size!
      dia .ed.list 2 array put
      dia .ed.buffer.list [ 63 string 127 string ] put
      dia .ed.text.list [ txt_server txt_directory ] put

      dia .ed.focus 0 put
    } ifelse
  } if

  dup .inst_smb eq {
    input.dialog.smb {
      /dia input.dialog.smb def
    } {
      /input.dialog.smb window.dialog def
      /dia input.dialog.smb def

      dia .dont_free 1 put

      dia .title txt_smb_title put
      dia .text "" put

      % Must all be of same size!
      dia .ed.list 4 array put
      dia .ed.buffer.list [ 63 string 127 string 31 string 31 string ] put
      dia .ed.text.list [ txt_server txt_directory txt_user2 txt_password ] put

      dia .ed.font font.normal put
      dia .ed.pw_field 3 put

      dia .ed.focus 0 put
    } ifelse
  } if

  pop

  dia .ed.width 240 put

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
    input.dialog.hd .ed.buffer.list get
    dup 1 get dup 0 get '/' eq { 1 add } if
    exch 0 get dup 0 get '/' eq { 1 add } if
    "install=hd://%s/%s" install.option sprintf
  } if

  dup .inst_ftp eq {
    input.dialog.ftp .ed.buffer.list get

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
    input.dialog.http .ed.buffer.list get
    dup 1 get dup 0 get '/' eq { 1 add } if
    exch 0 get
    "install=http://%s/%s" install.option sprintf
  } if

  dup .inst_nfs eq {
    input.dialog.nfs .ed.buffer.list get
    dup 1 get dup 0 get '/' eq { 1 add } if
    exch 0 get
    "install=nfs://%s/%s" install.option sprintf
  } if

  dup .inst_smb eq {
    input.dialog.smb .ed.buffer.list get

    "install=smb://" install.option sprintf

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

  pop

} def


/install.cancel {
  /xmenu xmenu.install def

  xmenu .xm_current install.last put

%  /window.action actRedrawPanel def
%  pmenu.update
} def

