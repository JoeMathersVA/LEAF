<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"/>

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
   /* reporting system menu buttons */ 
   #btn-enter-outreach-activities {
   	   background-color: #f7ed31; 
	   color: black;
       text-shadow: 2px 2px 1px rgba(0,0,15,0.2);
       margin-top: 0;
   }
   #btn-submit-quarterly-report {
        background-color: #2372b8; 
        color: white
   }
   #btn-enter-operations-plan {
       background-color: #300000;
       background-image: linear-gradient(0deg, #300000, #780040);
       color: white;
       
   }
    
   #btn-enter-partnerships {
    	background-color: #005852; 
       	background-image: linear-gradient(0deg, #004048, #006872);
        color: white;
   }
   #btn-enter-partnerships i {
   		color: #a0ffb8;
   }
   #btn-inbox {
    	background-color: #b8ef6d;
        text-shadow: 2px 2px 1px rgba(0,0,15,0.2);
   } 
    
    
</style>


<div id="mvpc-menu2">
  
    <!--- updated Reporting System Site --->
 	
    <a href="report.php?a=enter_outreach_activities" role="button">  
    <div class="mvpc-menuButtonSmall" id="btn-enter-outreach-activities">
        <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=document-new.svg&amp;w=50" />
        <div class="mvpc-menu-description">  
        	<h3 class="mvpc-menuTextSmall">Enter Outreach Activities</h3>
        </div>
    </div>
	</a>
    
    <a href="report.php?a=new_quarterly_report" role="button"> 
    <div class="mvpc-menuButtonSmall" id="btn-submit-quarterly-report">
        <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=document-new.svg&amp;w=50" />
        <div class="mvpc-menu-description">  
        	<h3 class="mvpc-menuTextSmall">Submit Quarterly Report</h3>
        </div>
    </div>
	</a>
    <!-- comment until release 
    <a href="report.php?a=enter_operations_plan" role="button">
    <div class="mvpc-menuButtonSmall" id="btn-enter-operations-plan">
        <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=format-justify-fill.svg&amp;w=50" />
        <div class="mvpc-menu-description">
        	<h3 class="mvpc-menuTextSmall">Operations Plan</h3>
        	<div class="mvpc-menuDescSmall">Enter Operations Plan</div>
        </div>
    </div>
	</a>
    <a href="report.php?a=Established_Partnerships" role="button">
    <div class="mvpc-menuButtonSmall" id="btn-enter-partnerships">
        <div class="icon"><i class="fa fa-handshake-o" style="font-size: 34px;"></i></div>
        <div class="mvpc-menu-description">
        	<h3 class="mvpc-menuTextSmall">Established Partnerships</h3>
        	<div class="mvpc-menuDescSmall">Enter Partnerships</div>
        </div>
    </div>
	</a> -->
    
    <!--{if $is_admin}-->  
    <a href="?a=inbox" role="button">
    <div class="mvpc-menuButtonSmall" id="btn-inbox">
         <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=document-open.svg&amp;w=50" />
         <div class="mvpc-menu-description">
         	<h3 class="mvpc-menuTextSmall">Inbox</h3>
         	<div class="mvpc-menuDescSmall">Review and apply actions to active requests</div>
        </div>
    </div>
    </a>
    <a href="?a=reports&v=3" role="button">
    <div class="mvpc-menuButtonSmall" style="background-color: black">
        <img class="mvpc-menuIconSmall" src="../libs/dynicons/?img=x-office-spreadsheet.svg&amp;w=50"/>
        <div class="mvpc-menu-description">
        	<h3 class="mvpc-menuTextSmall" style="color: white">Report Builder</h3>
            <div class="mvpc-menuDescSmall" style="color: white">Create custom reports</div>
        </div>
    </div>
    </a>
    
    <!--{/if}-->
    
    
    <a href="report.php?a=mvpc_document_library" role="button">
    <div class="mvpc-menuButtonSmall" style="background-color: black">
        <img src="../libs/dynicons/?img=x-office-address-book.svg&amp;w=50" />
		<div class="mvpc-menu-description">
        	<h3 class="mvpc-menuTextSmall" style="color: white">MVPC Document Library</h3>
        	<div class="mvpc-menuDescSmall" style="color: white"></div>
		</div>
    </div>
    </a> 
    
    
</div>

<!--{include file=$tpl_search is_service_chief=$is_service_chief is_admin=$is_admin empUID=$empUID userID=$userID}-->


