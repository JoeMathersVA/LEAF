<style>
    hr {
    margin: 2em;
    }
    /* mvpc classes / ids */

   	#mvpc-menu2, .mvpc-menuButtonSmall, .mvpc-menu-description,
    .mvpc-menuTextSmall, .mvpc-menuDescSmall {
        margin: 0;
        padding: 0;
        line-height: 1;
    	box-sizing: border-box;
        letter-spacing: 0.25px;
    }
    

   #mvpc-menu2 {
        display: flex;
        flex-direction: column;
        margin: 0 2.5em 1em 0;
        width: 285px;
        float: left;
   }
   #mvpc-menu2 a, #mvpc-menu2 a:hover, #mvpc-menu2 a:focus, #mvpc-menu2 a:visited {
        color: inherit;
        text-decoration: none;
   }
   .mvpc-menuButtonSmall {
    	display: flex;
        align-items: center;
        border-radius: 2px;
        height: 60px;
        width: 100%;
        padding: 6px;
        margin: 0.6em 0;
        box-shadow: 0px 2px 5px 1px rgba(0,0,35,0.4);
        text-shadow: 2px 2px 1px rgb(0,0,20);
        border: 1px outset #506078;
        transition: all 0.15s ease;
   }
   .mvpc-menuButtonSmall:hover, 
   .mvpc-menuButtonSmall:focus,
   .mvpc-menuButtonSmall:active {
    	box-shadow: 0 1px 0px 1px rgba(0,0,35,0.3);
        transform: translate(1px, 1px);
   }
   .mvpc-menuButtonSmall img,
   .mvpc-menuButtonSmall > div.icon {
        display: block;
    	margin-right: 8px;
        width: 46px;
        height: 46px;
        display: flex;
        justify-content: center;
        align-items: center;
   }
   .mvpc-menu-description {
        display: flex;
        flex-direction: column;
        height: 100%;
        justify-content:center;
   }
   .mvpc-menuTextSmall {
       	margin-bottom: 4px;
 		line-height: 1.12;
   }
   .mvpc-menuDescSmall {
    	font-size: 12px; 
		color:inherit;
   }
   /* overrides */
   img[id^="LeafFormSearch"] {
        display: none !important;
   }
   #bodyarea {
        padding: 1.5em; 
   }
   table.leaf_grid {
        margin: 0;
   }
   #btn-inbox {
    	background-color: #b8ef6d;
        text-shadow: 2px 2px 1px rgba(0,0,15,0.2);
   } 
    
    
   /* database buttons */ 
   #btn-help-desk {
   		background-color: #2372b0;
        color: white;
       margin-top: 0;
   }
   #btn-inbox {
    	background-color: #b8ef6d;
        text-shadow: 2px 2px 1px rgba(0,0,15,0.2);
   } 
   #btn-bookmarks {
       	background-color: #7eb2b3;
        text-shadow: 2px 2px 1px rgba(0,0,15,0.2);
   } 
   #btn-get-partnerships-by-date {
    	background-color: #003860;  
        color: white;
   }  
    #btn-get-operations-by-date {
        background-color: #c090d8;  
        background-image: linear-gradient(0deg,#a8a8d8,#b898e0); 
        color: black;
        text-shadow: 2px 2px 1px rgba(0,0,15,0.2);
    } 
    #btn-vha-info {
        background-color:#007050;
        background-image: linear-gradient(0deg,#003020,#007050);
    }
    #btn-vba-info {
        background-color:#504000;
        background-image: linear-gradient(0deg,#281800,#504000);
    }
    #btn-nca-info {
        background-color:#ab5800;
        background-image: linear-gradient(0deg,#482000,#ab5800);
    }
</style>



<div id="mvpc-menu2">  
    
    
    <!--- updated Database Site --->
    <a href="https://leaf.va.gov/Other/DEVTICKET/LEAF_Developer_Ticket_Requests/?a=newform" role="button">
    <div class="mvpc-menuButtonSmall" id="btn-help-desk">
        <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=document-new.svg&amp;w=50" />
        <div class="mvpc-menu-description">
        	<h3 class="mvpc-menuTextSmall">LEAF Help Desk</h3>
        <div class="mvpc-menuDescSmall">Create a help ticket</div>
        </div>
    </div>
	</a>
    
    <a href="?a=bookmarks" role="button">
    <div class="mvpc-menuButtonSmall" id="btn-bookmarks" style="background-color: #90b8c0">
        <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=bookmark.svg&amp;w=50" />
        <div class="mvpc-menu-description">
        	<h3 class="mvpc-menuTextSmall">Bookmarks</h3>
        	<div class="mvpc-menuDescSmall">View saved links to requests</div>
        </div>
    </div>
	</a>
    
    <a href="?a=inbox" role="button">
    <div class="mvpc-menuButtonSmall" id="btn-inbox">
         <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=document-open.svg&amp;w=50" />
         <div class="mvpc-menu-description">
         	<h3 class="mvpc-menuTextSmall">Inbox</h3>
         	<div class="mvpc-menuDescSmall">Review and apply actions to active requests</div>
        </div>
    </div>
    </a>
    
    <!--{if $is_admin}-->  
    <a href="?a=reports&v=3" role="button">
    <div class="mvpc-menuButtonSmall" style="background-color: black">
        <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=x-office-spreadsheet.svg&amp;w=50"/>
        <div class="mvpc-menu-description">
        	<h3 class="mvpc-menuTextSmall" style="color: white">Report Builder</h3>
            <div class="mvpc-menuDescSmall" style="color: white">Create custom reports</div>
        </div>
    </div>
    </a>
    
    <!-- NEED FULL URL, ON DATABASE SITE ONLY links to Reporting System from Database site -->
    <a href="https://leaf.va.gov/NATIONAL/MVPC/Reporting_System/report.php?a=query_estab_partnerships" role="button">
    <div class="mvpc-menuButtonSmall" id="btn-get-partnerships-by-date">
        <img src="../libs/dynicons/?img=edit-find.svg&amp;w=50"/>
        <div class="mvpc-menu-description">
        	<h3 class="mvpc-menuTextSmall">Partnerships Search</h3>
        	<div class="mvpc-menuDescSmall">Get entries by date range</div>
        </div>
    </div>
	</a> 
    <!-- NEED FULL URL, ON DATABASE SITE ONLY links to Reporting System from Database site -->
    <a href="https://leaf.va.gov/NATIONAL/MVPC/Reporting_System/report.php?a=query_operations_plan" role="button">
    <div class="mvpc-menuButtonSmall" id="btn-get-operations-by-date">
        <img src="../libs/dynicons/?img=edit-find.svg&amp;w=50"/>
        <div class="mvpc-menu-description">
        	<h3 class="mvpc-menuTextSmall">Operations Search</h3>
        	<div class="mvpc-menuDescSmall">Get entries by date range</div>
        </div>
    </div>
	</a> 
    
    <a href="open.php?report=32wmh" role="button">
    <div class="mvpc-menuButtonSmall" id="btn-vha-info">
        <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=x-office-spreadsheet.svg&amp;w=50" />
        <div class="mvpc-menu-description">
        	<h3 class="mvpc-menuTextSmall" style="color: white">VHA</h3>
        	<div class="mvpc-menuDescSmall" style="color: white">Information</div>
        </div>
    </div>
    </a>
    <a href="open.php?report=32wmj" role="button">
    <div class="mvpc-menuButtonSmall" id="btn-vba-info">
        <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=x-office-spreadsheet.svg&amp;w=50" /> 
       	<div class="mvpc-menu-description">
            <h3 class="mvpc-menuTextSmall" style="color: white">VBA</h3>
            <div class="mvpc-menuDescSmall" style="color: white">Information</div>
        </div>
    </div>
    </a>
    <a href="open.php?report=32wmi" role="button">
    <div class="mvpc-menuButtonSmall" id="btn-nca-info">
        <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=x-office-spreadsheet.svg&amp;w=50" />
        <div class="mvpc-menu-description"> 
        	<h3 class="mvpc-menuTextSmall" style="color: white">NCA</h3>
            <div class="mvpc-menuDescSmall" style="color: white">Information</div>
        </div>
    </div>
    </a>
    
    <a href="open.php?report=32wmr" role="button">
    <div class="mvpc-menuButtonSmall" style="background-color: black">
        <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=x-office-address-book.svg&amp;w=50" />
        <div class="mvpc-menu-description">  
        	<h3 class="mvpc-menuTextSmall" style="color: white">Administrators Document Library</h3>
            <div class="mvpc-menuDescSmall" style="color: white"></div>
        </div>
    </div>
    </a>
    
    <a href="open.php?report=32wmm" role="button">
    <div class="mvpc-menuButtonSmall" style="background-color: black">
        <img src="../libs/dynicons/?img=x-office-address-book.svg&amp;w=50" />
		<div class="mvpc-menu-description">
        	<h3 class="mvpc-menuTextSmall" style="color: white">MVPC Document Library</h3>
        	<div class="mvpc-menuDescSmall" style="color: white">Manage Uploads</div>
		</div>
    </div>
    </a> 
    <!--{/if}-->

</div>

<!--{include file=$tpl_search is_service_chief=$is_service_chief is_admin=$is_admin empUID=$empUID userID=$userID}-->
