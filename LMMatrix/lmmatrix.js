/*
 * LMPlayer
 * (c)2016 Kyoto University and DoGA
 */
var escapeHTML = function(val) {
	var elem = document.createElement('div');
	elem.appendChild(document.createTextNode(val));
	return elem.innerHTML;
};
/*改行をbr要素に変換*/
var newlineToBr = function(val) {
	return val.replace(/\r?\n/g, '<br />');
};

function getText(node) {
	if (node.childNodes.length > 0) {
		return node.childNodes[0].nodeValue;
	} else {
		return '';
	}
}

function getEscapedText(node) {
	return newlineToBr(escapeHTML(getText(node)));
}
/*xmlから表を生成*/
function processSubTree(tbody, nodeTree, parentText, needTr, level) {
	if (parentText === undefined) parentText = '';
	if (needTr === undefined) needTr = true;
	if (level === undefined) level = 1;
	var rowcount = 1;
	var text = '';
	var type = '';
	var htmlText = '';
	var subtree = new Array();
	for (var i = 0; i < nodeTree.childNodes.length; ++i) {
		switch (nodeTree.childNodes[i].nodeName) {
		case 'type':
			type = getText(nodeTree.childNodes[i]);
			break;
		case 'text':
			text = getEscapedText(nodeTree.childNodes[i]);
			break;
		case 'rows':
			rowcount = getText(nodeTree.childNodes[i]);
			break;
		case 'item':
			subtree.push(nodeTree.childNodes[i]);
			break;
		}
	}
	if (needTr) {
		htmlText = '<tr>';
	}
	htmlText += parentText;
	switch(type) {
	case 'multiRow':
		(function () {
			htmlText += '<th rowspan="' + rowcount + '" class="col' + level + '">' + text + '</th>';
			processSubTree(tbody, subtree[0], htmlText, false, level + 1);
			for (var i = 1; i < subtree.length; ++i) {
				processSubTree(tbody, subtree[i], '', true, level + 1);
			}
		}) ();
		break;
	case 'row':
		(function () {
			var text;
			var th_item = nodeTree.getElementsByTagName('header')[0].getElementsByTagName('item');
			var td_item = nodeTree.getElementsByTagName('data')[0].getElementsByTagName('item');
			for (var i = 0; i < th_item.length; ++i) {
				for (var j = 0; j < th_item[i].childNodes.length; ++j) {
					switch (th_item[i].childNodes[j].nodeName) {
					case 'text':
						text = getEscapedText(th_item[i].childNodes[j]);
						break;
					}
				}
				htmlText += '<th class="col' + level + '">' + text + '</th>';
				++level;
			}
			for (var i = 0; i < td_item.length; ++i) {
				var buttonHtml = '';
				for (var j = 0; j < td_item[i].childNodes.length; ++j) {
					switch (td_item[i].childNodes[j].nodeName) {
					case 'text':
						text = getEscapedText(td_item[i].childNodes[j]);
						break;
					case 'bookmark':
						(function () {
							var text = '';
							var path = '';
							var target = '';
							var sttime = '';
							var edtime = '';
							for (var k = 0; k < td_item[i].childNodes[j].childNodes.length; ++k) {
								switch (td_item[i].childNodes[j].childNodes[k].nodeName) {
								case 'text':
									text = getEscapedText(td_item[i].childNodes[j].childNodes[k]);
									break;
								case 'path':
									path = getText(td_item[i].childNodes[j].childNodes[k]);
									target = 'lmplayer' + path.replace(/[^A-Za-z\d]/g, '');
									break;
								case 'startTime':
									sttime = getEscapedText(td_item[i].childNodes[j].childNodes[k]);
									break;
								case 'endTime':
									edtime = getEscapedText(td_item[i].childNodes[j].childNodes[k]);
									break;
								}
							}
							if (sttime != '' && edtime != '') {
								path += '#sttime=' + sttime + '&edtime=' + edtime;
							}
							buttonHtml += '<a href="' + path + '" target="' + target + '">' + text + '</a>';
						})();
						break;
					}
				}
				htmlText += '<td class="col' + level + '">' + text + buttonHtml + '</td>';
				++level;
			}
			htmlText += '</tr>';
			tbody.insertAdjacentHTML('beforeend', htmlText);
		}) ();
		break;
	}
}

function buildMatrix(xmldata) {
	var title = '';
	var titleNode = xmldata.getElementsByTagName('title');
	if (titleNode.length > 0) {
		title = titleNode[0].textContent;
	}
	document.getElementById('matrix_title').innerHTML = title;
	var table = document.getElementsByTagName('table')[0];
	var thead = table.getElementsByTagName('thead')[0];
	var theadTexts = xmldata.getElementsByTagName('tableHeader')[0].getElementsByTagName('text');
	var theadhtml = '<tr>';
	for (var i = 0; i < theadTexts.length; ++i) {
		var text = newlineToBr(escapeHTML(theadTexts[i].childNodes[0].nodeValue));
		theadhtml += '<th class="col'+ (i + 1) + '">' + text + '</th>';
	}
	theadhtml += '</tr>';
	thead.insertAdjacentHTML('beforeend', theadhtml);
	var tbody = table.getElementsByTagName('tbody')[0];
	var tbodyData = xmldata.getElementsByTagName('tableBody')[0];
	for (var i = 0; i < tbodyData.childNodes.length; ++i) {
		processSubTree(tbody, tbodyData.childNodes[i]);
	}
	var btnelm = tbody.getElementsByTagName('a');
	for (var i = 0; i < btnelm.length; ++i) {
		btnelm[i].addEventListener('click', function(e) {
			var hrefOrig = e.currentTarget.href;
			var rndprm = ('' + Math.random()).substr(0, 8);
			if (hrefOrig.indexOf('#') >= 0) {
				var pos = hrefOrig.indexOf('rnd=');
				if (pos >= 0) {
					e.currentTarget.href = hrefOrig.substr(0, pos + 4) + rndprm;
				} else {
					e.currentTarget.href = hrefOrig + '&rnd=' + rndprm;
				}
			} else {
				e.currentTarget.href = hrefOrig + '#rnd=' + rndprm;
			}
		});
	}
}

function setupMatrix(xmlfname) {
	var protocol = window.location.protocol;
	var xhr = null;
	var xmlDoc = null;
	var supportActiveX = (Object.getOwnPropertyDescriptor && Object.getOwnPropertyDescriptor(window, "ActiveXObject")) || ("ActiveXObject" in window);
	if (window.XMLHttpRequest && !(protocol == 'file:' && supportActiveX)) {
		xhr = new XMLHttpRequest();
	} else {
		if (supportActiveX) {
			if (protocol == 'file:') {
				xmlDoc = new ActiveXObject("Msxml2.DOMDocument.6.0");
			} else {
				xhr = new ActiveXObject('MSXML2.XMLHTTP.3.0');
			}
		}
	}

	if (xhr) {
		xhr.open("GET", xmlfname, true);

		var requestDone = false;
		var onreadystatechange = function() {
			if(!requestDone && xhr && xhr.readyState == 4) {
				requestDone = true;

				if (ival) {
					clearInterval(ival);
					ival = null;
				}

				buildMatrix(xhr.responseXML);
			}
		}

		var ival = setInterval(onreadystatechange, 13);

		try{
			xhr.send(null);
		} catch(e) {
			alert(e);
		}
	} else if (xmlDoc) {
		var xmlDoc = new ActiveXObject("Msxml2.DOMDocument.6.0");
		xmlDoc.async = false;
		xmlDoc.load(xmlfname);
		if (xmlDoc.parseError.errorCode != 0) {
			var myErr = xmlDoc.parseError;
			WScript.Echo("You have error " + myErr.reason);
		} else {
			buildMatrix(xmlDoc.documentElement);
			return;
		}
	} else {
		alert('この環境では使用できません');
	}
}

