{strip}<!DOCTYPE html>
<html lang="en">
<head>
    <title>{$title|sanitize}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style type="text/css" media="screen">
        @import "css/style.css";
    </style>
    <style type="text/css" media="print">
        @import "css/printer.css";
    </style>
</head>
<body>
    <div id="header">
        <div style="cursor: pointer" onclick="window.location='./'">
            <span style="position: absolute"><img src="images/VA_icon_small.png" style="width: 80px" alt="VA logo" /></span>
            <span id="headerDescription">{$title|sanitize}</span>
        </div>
        <span id="headerTab"></span>
        <span id="headerTabImg"><img src="images/tab.png" alt="tab" /></span>
    </div>
    <div id="body">
        <div id="content">
            <div id="bodyarea">
                <div class="card" style="width: 50%; margin: auto; padding: 16px">
                    <h2>Your Session Has Expired</h2>
                    <p>Return to your <a href="./login">LEAF site</a></p>
                    <p>If this message persists, please contact your administrator.</p>
                </div>
            </div>
        </div>
    </div>
</body>
</html>{/strip}

