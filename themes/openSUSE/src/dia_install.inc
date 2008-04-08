% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Install mode selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/install.option 255 string def

% install types
/.inst_cdrom	0 def
/.inst_slp	1 def
/.inst_ftp	2 def
/.inst_http	3 def
/.inst_nfs	4 def
/.inst_smb	5 def
/.inst_hd	6 def

/install.last .inst_cdrom def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build install mode list.
%
% ( ) ==> ( )
%
/install.init {
  /xmenu.install .xm_size array def

  /xmenu xmenu.install def

  /input.edit.ftp [ 63 string 127 string 31 string 31 string ] def
  /input.edit.http [ 63 string 127 string ] def
  /input.edit.nfs [ 63 string 127 string ] def
  /input.edit.smb [ 63 string 31 string 127 string 31 string 31 string 31 string ] def
  /input.edit.hd [ 63 string 127 string ] def

  install.read.config

  xmenu .xm_current install.last put

  % see install types (.inst_*)
  xmenu .xm_list [ is_dvd { "DVD" } { "CD-ROM" } ifelse "SLP" "FTP" "HTTP" "NFS" "SMB / CIFS" /txt_harddisk ] put

  xmenu .xm_title /txt_install_source put

  install.set.install.option
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

    install.set.install.option

    /window.action actRedrawPanel def
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

  dup .inst_ftp eq {
    dia .title txt_ftp_title put

    % Must all be of same size!
    dia .ed.list 4 array put
    dia .ed.buffer.list input.edit.ftp put
    dia .ed.text.list [ txt_server txt_directory txt_user1 txt_password ] put

    dia .ed.font font.normal put
    dia .ed.pw_field 3 put

  } if

  dup .inst_http eq {
    dia .title txt_http_title put

    % Must all be of same size!
    dia .ed.list 2 array put
    dia .ed.buffer.list input.edit.http put
    dia .ed.text.list [ txt_server txt_directory ] put

  } if

  dup .inst_nfs eq {
    dia .title txt_nfs_title put

    % Must all be of same size!
    dia .ed.list 2 array put
    dia .ed.buffer.list input.edit.nfs put
    dia .ed.text.list [ txt_server txt_directory ] put

  } if

  dup .inst_smb eq {
    dia .title txt_smb_title put

    % Must all be of same size!
    dia .ed.list 6 array put
    dia .ed.buffer.list input.edit.smb put
    dia .ed.text.list [ txt_server txt_share txt_directory txt_domain txt_user2 txt_password ] put

    dia .ed.font font.normal put
    dia .ed.pw_field 5 put

  } if

  dup .inst_hd eq {
    dia .title txt_harddisk_title put

    % Must all be of same size!
    dia .ed.list 2 array put
    dia .ed.buffer.list input.edit.hd put
    dia .ed.text.list [ txt_hd_diskdevice txt_directory ] put

  } if

  pop

  dia .ed.focus 0 put
  dia .ed.width 300 put

  dia .buttons [
    button.ok button.default actInstallOK actNoClose or button.setaction
    button.cancel button.notdefault actInstallCancel button.setaction
    config.rtl { exch } if
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

  install.set.install.option

} def


/install.cancel {
  /xmenu xmenu.install def

  xmenu .xm_current install.last put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Set 'install=' boot option.
%
% ( -- )
%
/install.set.install.option {
  xmenu .xm_current get

  % default: .inst_cdrom
  install.option "" strcpy pop

  dup .inst_slp eq {
    install.option "install=slp:/" strcpy pop
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
    dup 3 get "" ne {
      dup 3 get "%s;" install.option dup length add sprintf
    } if

    % add user name & password
    dup 4 get "" ne {
      dup 4 get "%s" install.option dup length add sprintf
      dup 5 get "" ne {
        dup 5 get ":%s" install.option dup length add sprintf
      } if
      "@" install.option dup length add sprintf
    } if

    dup 2 get dup 0 get '/' eq { 1 add } if
    over 1 get rot 0 get
    "%s/%s/%s" install.option dup length add sprintf
  } if

  dup .inst_hd eq {
    input.edit.hd
    dup 1 get dup 0 get '/' eq { 1 add } if
    exch 0 get dup 0 get '/' eq { 1 add } if
    "install=hd://%s/%s" install.option sprintf
  } if

  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Read default values.
%
% ( -- )
%
/install.read.config {
  "install" getgfxconfig
  dup "cdrom" eq { /install.last .inst_cdrom def } if
  dup "slp"   eq { /install.last .inst_slp   def } if
  dup "ftp"   eq { /install.last .inst_ftp   def } if
  dup "http"  eq { /install.last .inst_http  def } if
  dup "nfs"   eq { /install.last .inst_nfs   def } if
  dup "smb"   eq { /install.last .inst_smb   def } if
  dup "hd"    eq { /install.last .inst_hd    def } if
  pop

  "install.http.server"  input.edit.http 0 get getgfxconfig.str
  "install.http.path"    input.edit.http 1 get getgfxconfig.str

  "install.nfs.server"   input.edit.nfs  0 get getgfxconfig.str
  "install.nfs.path"     input.edit.nfs  1 get getgfxconfig.str

  "install.smb.server"   input.edit.smb  0 get getgfxconfig.str
  "install.smb.share"    input.edit.smb  1 get getgfxconfig.str
  "install.smb.path"     input.edit.smb  2 get getgfxconfig.str
  "install.smb.domain"   input.edit.smb  3 get getgfxconfig.str
  "install.smb.user"     input.edit.smb  4 get getgfxconfig.str
  "install.smb.password" input.edit.smb  5 get getgfxconfig.str

  "install.hd.device"    input.edit.hd   0 get getgfxconfig.str
  "install.hd.path"      input.edit.hd   1 get getgfxconfig.str

} def


