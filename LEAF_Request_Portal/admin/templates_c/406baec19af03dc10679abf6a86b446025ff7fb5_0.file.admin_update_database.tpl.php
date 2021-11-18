<?php
/* Smarty version 3.1.33, created on 2021-10-10 02:20:41
  from '/var/www/html/LEAF_Request_Portal/admin/templates/admin_update_database.tpl' */

/* @var Smarty_Internal_Template $_smarty_tpl */
if ($_smarty_tpl->_decodeProperties($_smarty_tpl, array (
  'version' => '3.1.33',
  'unifunc' => 'content_61624df955e0b6_26607518',
  'has_nocache_code' => false,
  'file_dependency' => 
  array (
    '406baec19af03dc10679abf6a86b446025ff7fb5' => 
    array (
      0 => '/var/www/html/LEAF_Request_Portal/admin/templates/admin_update_database.tpl',
      1 => 1632320005,
      2 => 'file',
    ),
  ),
  'includes' => 
  array (
  ),
),false)) {
function content_61624df955e0b6_26607518 (Smarty_Internal_Template $_smarty_tpl) {
?><div class="leaf-center-content">

     <aside class="sidenav-right"></aside>

    <aside class="sidenav"></aside>
    
    <main class="main-content">
    
        <h2>Update Database</h2>
        
        <div id="toolbar" class="toolbar_right toolbar noprint" style="position: absolute; right: 2px"></div>

        <div style="width: 85%">

            <div id="groupList"></div>
        </div>

        <div id="editdialog1" style="visibility: hidden">
            <div>
                <div id="editxhr" style="width: 500px; height: 400px; overflow: auto">
                    <div style="position: absolute; left: 10px"><button id="button_cancelchange"><img src="../../libs/dynicons/?img=process-stop.svg&amp;w=16" alt="cancel" /> Cancel</button></div>
                    <div style="border-bottom: 2px solid black; text-align: right"><br />&nbsp;<!--<button id="button_save"><img src="../../libs/dynicons/?img=list-add.svg&amp;w=16" alt="save" /> Add user</button>--></div><br />            
                    <span>Search: </span><input id="query" type="text" /><div id="loadIndicator" style="visibility: hidden; float: right"><img src="../images/indicator.gif" alt="loading..." /></div>
                    <div id="results"></div>        
                </div>
            </div>
        </div>

    </main>

</div>

<?php echo '<script'; ?>
 type="text/javascript">
/* <![CDATA[ */

$(function() {
    $('#groupList').html('<div style="border: 2px solid black; text-align: center; font-size: 24px; font-weight: bold; background: white; padding: 16px; width: 95%">Loading... <img src="../images/largespinner.gif" alt="loading..." /></div>');

    $.ajax({
    	type: 'GET',
        url: "../scripts/updateDatabase.php",
        success: function(response) {
            $('#groupList').html('<pre>' + response + '</pre>');
        }
    });
});

/* ]]> */
<?php echo '</script'; ?>
><?php }
}
