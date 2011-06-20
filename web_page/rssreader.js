var number_of_msgs = 5;	// number of messages to show at startup
var more_button	= true; // show more messages button
var hide_button = false; // hide messages button
var RSSRequestObject = false; // XMLHttpRequest Object
var Backend = 'http://sourceforge.net/export/rss2_projnews.php?group_id=513143'; // Backend url
var Backend_short="news"
window.setInterval("update_timer()", 1200000); // update the data every 20 mins


if (window.XMLHttpRequest) // try to create XMLHttpRequest
	RSSRequestObject = new XMLHttpRequest();

if (window.ActiveXObject)	// if ActiveXObject use the Microsoft.XMLHTTP
	RSSRequestObject = new ActiveXObject("Microsoft.XMLHTTP");


/*
* onreadystatechange function
*/
function ReqChange() {

	// If data received correctly
	if (RSSRequestObject.readyState==4) {
	
		// if data is valid
		if (RSSRequestObject.responseText.indexOf('invalid') == -1) 
		{ 	
			// Parsing RSS
			var node = RSSRequestObject.responseXML.documentElement; 
			
			
			// Get Channel information
			var channel = node.getElementsByTagName('channel').item(0);
			var title = channel.getElementsByTagName('title').item(0).firstChild.data;
			var link = channel.getElementsByTagName('link').item(0).firstChild.data;
			
			// content = '<div class="channeltitle"><a href="'+link+'">'+title+'</a></div><ul>';
			if (Backend_short == "news")
			{
			    content = '<table class=rsstable><tr><td><br><table align=center><tr><td><a class=button_on onclick="GetNews();">News</a></td><td><a class=button_off onclick="GetActivity();">Activity</a></td><td><a class=button_off onclick="GetReleases();">Releases</a></td></tr></table><ul>';
			}
			if (Backend_short == "activity")
			{
			    content = '<table class=rsstable><tr><td><br><table align=center><tr><td><a class=button_off onclick="GetNews();">News</a></td><td><a class=button_on onclick="GetActivity();">Activity</a></td><td><a class=button_off onclick="GetReleases();">Releases</a></td></tr></table><p align="center" style="line-height: 50%;"><a href="http://atp-vim.svn.sourceforge.net/viewvc/atp-vim/">svn repository</a></p><ul>';
			}

			if (Backend_short == "releases")
			{
			    content = '<table class=rsstable><tr><td><br><table align=center><tr><td><a class=button_off onclick="GetNews();">News</a></td><td><a class=button_off onclick="GetActivity();">Activity</a></td><td><a class=button_on onclick="GetReleases();">Releases</a></td></tr></table><p align="center" style="line-height: 50%;">click link to download</p><ul>';
			}
		
			// Browse items
			var items = channel.getElementsByTagName('item');
			for (var n=0; n < number_of_msgs; n++)
			{
				var itemTitle = items[n].getElementsByTagName('title').item(0).firstChild.data;
				var itemLink = items[n].getElementsByTagName('link').item(0).firstChild.data;
				var description = items[n].getElementsByTagName('description').item(0).firstChild.data;
				try 
				{ 
				    var itemPubDate = '<font color=gray>['+items[n].getElementsByTagName('pubDate').item(0).firstChild.data+']';
				} 
				catch (e) 
				{ 
					var itemPubDate = '';
				}
				
			
				if (n == 5 && number_of_msgs > 5)
				{
				    content += '<hr class="leftpanel">'
				}

				if (Backend_short == "releases")
				{
				    content += '<li style="padding: 5px 0px;" title="'+itemTitle+'">'+itemPubDate+'</font><div class=rsstitle2><a href="http://sourceforge.net/projects/atp-vim/files/'+description+'">'+itemTitle+'</a></div>';
				}
				else
				{
				    content += '<li style="padding: 5px 0px;" title="'+itemTitle+'">'+itemPubDate+'</font><div class=rsstitle2>'+itemTitle+'</div>';
				}

				if (Backend_short == "news")
				{
				    content +=description;
				}
				content += '</li>'
			}
			
			
			content += '</ul></td></tr>';
			if (more_button)
			{
				content += '<td align="center"><input type="button" value="get more" onClick="GetMoreNews();"></input></td></tr>';
			}
			else
			{
			    	content += '<tr><td><input type="button" value="hide" onClick="HideNews();"></input></td></tr><tr><td>To read more visit <a style="color:#2E006C; text-decoration:none;" href="https://sourceforge.net/news/?group_id=513143"><b>News at SourceForge</b></a>.</td></tr>';
			}
		        content += '</table>';
			// Display the result
			document.getElementById("rssreader").innerHTML = content;

			// Tell the reader the everything is done
			// document.getElementById("status").innerHTML = "Done.";
			
		}
		else {
			// Tell the reader that there was error requesting data
			document.getElementById("status").innerHTML = "<div class=error>Error requesting data.<div>";
		}
		
		HideShow('status');
	}
	
}

/*
* Main AJAX RSS reader request
*/
function RSSRequest() {

	// change the status to requesting data
	HideShow('status');
	// document.getElementById("status").innerHTML = '<table><td align=center><b>Fetching RSS feed ...</b></td></table>'; 
	// Prepare the request
	RSSRequestObject.open("GET", Backend , true);
	// Set the onreadystatechange function
	RSSRequestObject.onreadystatechange = ReqChange;
	// Send
	RSSRequestObject.send(null); 
}

/*
* Timer
*/
function update_timer() {
	RSSRequest();
}


function HideShow(id){
	var el = GetObject(id);
	if(el.style.display=="none")
	el.style.display='';
	else
	el.style.display='none';
}

function GetObject(id){
	var el = document.getElementById(id);
	return(el);
}

function GetMoreNews() {
	number_of_msgs = 10; // there are only 10 messages in the channel
	more_button = false;
	hide_button = true;
	RSSRequest();
}
function HideNews() {
	number_of_msgs = 5; // there are only 10 messages in the channel
	more_button = true;
	hide_button = false;
	RSSRequest();
}

function GetNews() {
    	Backend =  'http://sourceforge.net/export/rss2_projnews.php?group_id=513143'
	Backend_short="news"
	RSSRequest()
}

function GetActivity() {
	Backend = 'http://sourceforge.net/export/rss2_keepsake.php?group_id=513143'
	Backend_short="activity"
	RSSRequest()
}	

function GetReleases() {
	Backend = 'http://sourceforge.net/api/file/index/project-id/513143/mtime/desc/limit/20/rss'
	Backend_short="releases"
	RSSRequest()
}	
