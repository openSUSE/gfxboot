% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Install mode selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/install.option 255 string def
/proxy.option 255 string def

% install types
/.inst_cdrom	0 def
/.inst_hd	1 def
/.inst_slp	2 def
/.inst_ftp	3 def
/.inst_http	4 def
/.inst_nfs	5 def
/.inst_smb	6 def
/.inst_net_setup 7 def
/.inst_net_proxy 8 def

/install.default .inst_cdrom def

% isohybrid image booted as disk
sectorsize 0x200 eq bootdrive 0x80 eq or {
  /install.default .inst_hd def
} if

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
  /input.edit.proxy [ 63 string 127 string 63 string 63 string ] def

  install.read.config

  xmenu .xm_current install.default put

  % see install types (.inst_*)
  xmenu .xm_list [
    is_dvd { "DVD" } { "CD-ROM" } ifelse
    /txt_harddisk
    "\x09SLP"
    "FTP"
    "HTTP"
    "NFS"
    "SMB / CIFS"
    /install.submenu.net
    /txt_http_proxy
  ] put

  xmenu .xm_title /txt_install_source put

  install.set.install.option

  % needed in case menu is only attached to install menu
  net.init
} def


/install.submenu.net.buf 64 string def
/install.submenu.net {
  /txt_network_config exec "\x09\x09%s" install.submenu.net.buf sprintf
  install.submenu.net.buf
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update install mode.
%
% ( ) ==> ( )
%
/install.update {
  /xmenu xmenu.install def

  xmenu .xm_current get .inst_net_setup eq {
    xmenu .xm_current over .xm_last get put
    panel.net
  } {
    xmenu .xm_current get dup .inst_cdrom eq exch .inst_slp eq or {
      install.set.install.option
      /window.action actRedrawPanel def
    } {
      install.dialog
    } ifelse
  } ifelse

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

  xmenu.net .xm_panel_x xmenu.install .xm_panel_x get put
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

  dup .inst_net_proxy eq {
    dia .title "HTTP Proxy" put

    % Must all be of same size!
    dia .ed.list 4 array put
    dia .ed.buffer.list input.edit.proxy put
    dia .ed.text.list [ txt_server "Port\n" "User\n" txt_password ] put

    dia .ed.font font.normal put
    dia .ed.pw_field 3 put

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

  /window.action actRedrawPanel def

  pmenu.update

  install.set.install.option

  xmenu .xm_current get .inst_net_proxy eq {
    xmenu .xm_current over .xm_last get put
  } if
} def


/install.cancel {
  /xmenu xmenu.install def

  xmenu .xm_current over .xm_last get put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Set 'install=' boot option.
%
% ( -- )
%
/install.set.install.option {
  xmenu .xm_current get

  dup .inst_net_proxy ne {
    % default: .inst_cdrom
    install.option "" strcpy pop
  } if

  dup .inst_slp eq {
    install.option "install=slp:/" strcpy pop
  } if

  dup .inst_ftp eq {
    input.edit.ftp

    "install=ftp://" install.option sprintf

    % add user name & password
    dup 2 get "" ne {
      dup 2 get url_escape "%s" install.option dup length add sprintf
      dup 3 get "" ne {
        dup 3 get url_escape ":%s" install.option dup length add sprintf
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
      dup 4 get url_escape "%s" install.option dup length add sprintf
      dup 5 get "" ne {
        dup 5 get url_escape ":%s" install.option dup length add sprintf
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

  dup .inst_net_proxy eq {
    input.edit.proxy
      dup 0 get "" ne {
      "proxy=http://" proxy.option sprintf
      % add user name & password
      dup 2 get "" ne {
        dup 2 get url_escape "%s" proxy.option dup length add sprintf
        dup 3 get "" ne {
          dup 3 get url_escape ":%s" proxy.option dup length add sprintf
        } if
        "@" proxy.option dup length add sprintf
      } if

      dup 1 get exch 0 get "%s:%s" proxy.option dup length add sprintf
    } {
      pop
      proxy.option "" strcpy pop
    } ifelse
  } if

  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Read default values.
%
% ( -- )
%
/install.read.config {
  install.install
  dup "cdrom" eq { /install.default .inst_cdrom def } if
  dup "slp"   eq { /install.default .inst_slp   def } if
  dup "ftp"   eq { /install.default .inst_ftp   def } if
  dup "http"  eq { /install.default .inst_http  def } if
  dup "nfs"   eq { /install.default .inst_nfs   def } if
  dup "smb"   eq { /install.default .inst_smb   def } if
  dup "hd"    eq { /install.default .inst_hd    def } if
  pop

  input.edit.http 0 get install.http.server strcpy pop
  input.edit.http 1 get install.http.path strcpy pop

  input.edit.nfs  0 get install.nfs.server strcpy pop
  input.edit.nfs  1 get install.nfs.path strcpy pop

  input.edit.ftp  0 get install.ftp.server strcpy pop
  input.edit.ftp  1 get install.ftp.path strcpy pop
  input.edit.ftp  2 get install.ftp.user strcpy pop
  input.edit.ftp  3 get install.ftp.password strcpy pop

  input.edit.smb  0 get install.smb.server strcpy pop
  input.edit.smb  1 get install.smb.share strcpy pop
  input.edit.smb  2 get install.smb.path strcpy pop
  input.edit.smb  3 get install.smb.domain strcpy pop
  input.edit.smb  4 get install.smb.user strcpy pop
  input.edit.smb  5 get install.smb.password strcpy pop

  input.edit.hd   0 get install.hd.device strcpy pop
  input.edit.hd   1 get install.hd.path strcpy pop

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Escape ("%XX") fishy chars.
%
% ( str1 -- str2 )
%
% Note: the returned string is a static buffer.
%
/url_escape {
  /url_esc_idx 0 def

  {
    /url_esc_c exch def
    url_esc_c '0' ge url_esc_c '9' le and
    url_esc_c 'A' ge url_esc_c 'Z' le and or
    url_esc_c 'a' ge url_esc_c 'z' le and or
    url_esc_c '_' eq or
    {
      url_esc_buf url_esc_idx url_esc_c put
      /url_esc_idx inc
    } {
      url_esc_c "%%%02x" url_esc_buf url_esc_idx add sprintf
      /url_esc_idx url_esc_idx 3 add def
    } ifelse
  } forall

  url_esc_buf dup url_esc_idx 0 put
} def

/url_esc_buf 256 string def


