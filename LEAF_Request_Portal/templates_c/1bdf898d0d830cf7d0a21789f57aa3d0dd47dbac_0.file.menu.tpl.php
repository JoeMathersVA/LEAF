<?php
/* Smarty version 3.1.33, created on 2021-10-09 21:00:58
  from '/var/www/html/LEAF_Request_Portal/templates/menu.tpl' */

/* @var Smarty_Internal_Template $_smarty_tpl */
if ($_smarty_tpl->_decodeProperties($_smarty_tpl, array (
  'version' => '3.1.33',
  'unifunc' => 'content_61623b4a0cb3f3_51164941',
  'has_nocache_code' => false,
  'file_dependency' => 
  array (
    '1bdf898d0d830cf7d0a21789f57aa3d0dd47dbac' => 
    array (
      0 => '/var/www/html/LEAF_Request_Portal/templates/menu.tpl',
      1 => 1633811349,
      2 => 'file',
    ),
  ),
  'includes' => 
  array (
    'file:menu_links.tpl' => 1,
    'file:menu_help.tpl' => 1,
  ),
),false)) {
function content_61623b4a0cb3f3_51164941 (Smarty_Internal_Template $_smarty_tpl) {
if ($_smarty_tpl->tpl_vars['action']->value != '') {?>
    <a href="./" class="buttonNorm"><img src="../libs/dynicons/?img=go-home.svg&amp;w=16" role="button" />Main Page</a>
<?php }?>
<div id="headerMenu_container" style="display: inline-block">
    <a id="button_showLinks" tabindex="0" class="buttonNorm" alt="Links Dropdown" title="Links" aria-haspopup="true" aria-expanded="false" role="button">Links</a>
    <div id="headerMenu_links">
    <?php $_smarty_tpl->_subTemplateRender("file:menu_links.tpl", $_smarty_tpl->cache_id, $_smarty_tpl->compile_id, 0, $_smarty_tpl->cache_lifetime, array(), 0, false);
?>
    </div>
</div>
<div id="headerMenuHelp_container" style="display: inline-block">
    <a id="button_showHelp" tabindex="0" class="buttonNorm" alt="Help Popup" title="Help" aria-haspopup="true" aria-expanded="false" role="button"><img style="vertical-align: sub;" src="../libs/dynicons/?img=help-browser.svg&amp;w=16">&nbsp;Help</a>
    <div id="headerMenu_help" tabindex="0">
    <?php $_smarty_tpl->_subTemplateRender("file:menu_help.tpl", $_smarty_tpl->cache_id, $_smarty_tpl->compile_id, 0, $_smarty_tpl->cache_lifetime, array(), 0, false);
?>
    </div>
</div>
<?php if ($_smarty_tpl->tpl_vars['is_admin']->value == true) {?>
     <a href="./admin/" class="buttonNorm" role="button"><img src="../libs/dynicons/?img=applications-system.svg&amp;w=16"/>Admin Panel</a>
<?php }
if ($_smarty_tpl->tpl_vars['hide_main_control']->value == 1) {
}?>

<?php echo '<script'; ?>
>

    menu508($('#button_showLinks'), $('#headerMenu_links'), $('#headerMenu_links').find('a'));
    menu508($('#button_showHelp'), $('#headerMenu_help'), $('#headerMenu_help'));

    function menu508(menuButton, subMenu, subMenuButton)
    {
        $(menuButton).keydown(function(e) {
            if (e.keyCode === 13) {
                $(subMenu).css("display", "block");
                $(menuButton).attr('aria-expanded', 'true');
                subMenuButton.focus();
            }
        });

        $(menuButton).focusout(function() {
            $(subMenu).css("display", "none");
            $(menuButton).attr('aria-expanded', 'false');
        });
    }
<?php echo '</script'; ?>
>

<br />
<noscript><div class="alert"><span>Javascript must be enabled for this version of software to work!</span></div></noscript>
<?php }
}
