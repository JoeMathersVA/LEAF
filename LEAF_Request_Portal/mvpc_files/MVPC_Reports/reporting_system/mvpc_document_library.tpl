<style>
    #content {
    	margin: 1em;
    }
    #bodyarea {
    	width: fit-content;
        width: -moz-fit-content;
    }
    table[id^="LeafFormGrid"] {
    	margin: 0 auto 0 0;
    }
    #grid {
    	border: 1px outset black;
    }
    #grid > p {
        background-color: #c0d0f0;
    	padding: 0.5em 0.7em;
    	font-weight: bold;
        border-bottom: 1px solid rgba(0,50,100,0.2);
        margin: 0;
        font-size: 1rem;
    }
    
    .mvpc-document-link {
    	display: block;
        line-height: 1.2;
        padding: 0.5em 0.7em;
        color: black !important;
        text-decoration: none;
        background-color: #e8f0ff;
        border-bottom: 1px solid rgba(0,50,100,0.1);
        font-size: 0.9rem;
    }
    .mvpc-document-link:hover, .mvpc-document-link:focus, .mvpc-document-link:active {
    	background-color: #fff;
    }
</style>    

<h2>Information and Training Resources</h2>

<script>
/*  form_52dd6,  ind32    */
    
function sortArr(arrP, start = 0, end = arrP.length-1, copy = true){
	if (start >= end) return;
    let arr = copy ? arrP.slice() : arrP;
    
    let p = start;
    let v = arr[end].s1.id32;  //sorting according to file name
    for (let i = start; i < end; i++) {
    	if (arr[i].s1.id32 < v) {
        	[ arr[i], arr[p] ] = [ arr[p], arr[i] ];
            p++;
        }
    }
    [ arr[end], arr[p] ] = [ arr[p], arr[end] ];
    sortArr(arr, start, p-1, false);
    sortArr(arr, p + 1, end, false);
    return arr;
}
  
    
var query; 
function getData() {
    
    query = new LeafFormQuery();
    query.setRootURL('../Database/');
 	query.importQuery({"terms":[{"id":"categoryID","operator":"=","match":"form_52dd6","gate":"AND"},{"id":"deleted","operator":"=","match":0,"gate":"AND"}],"joins":[""],"sort":{},"getData":["32"]});
  
	query.onSuccess(function(res) {
        let arrRes = [];
        for (let k in res){
            if (typeof res[k].s1.id32 !== 'undefined' && res[k].s1.id32 !== null){
        		arrRes.push(res[k]);
            }
        }
        let sortedArr = sortArr(arrRes);
    
        let elGrid = document.getElementById('grid');
		let char = '';
        sortedArr.forEach(ele => {
            let anchor = document.createElement("a");
            anchor.setAttribute("class", "mvpc-document-link");
            let link = `../Database/file.php?form=${ele.recordID}&id=32&series=1&file=0`;
            anchor.setAttribute("href", link);
            anchor.setAttribute("download", `${ele.s1.id32}`);
      		anchor.textContent = `${ele.s1.id32}`;
            if(ele.s1.id32[0] > char){
                char = ele.s1.id32[0];
                let p = document.createElement("p");
                p.textContent = ele.s1.id32[0];
            	elGrid.appendChild(p);
            }
            elGrid.appendChild(anchor);
        });
    });
    query.execute();
}

    
$(function() {
    $('#headerTab').html('MVPC Document Library');
    getData();
}); 

</script>
<div id="grid"></div>