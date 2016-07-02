/*
 * LMPlayer
 * (c)2016 Kyoto University and DoGA
 */
var escapeHTML = function(val) {
	var elem = document.createElement('div');
	elem.appendChild(document.createTextNode(val));
	return elem.innerHTML;
};
//クエリ文字列をオブジェクトに変換
function qstrToObj(qstr) {
	var params = qstr.split('&');
	var paramObj = new Object();
	for (var i=0; i<params.length; i++) {
		var pos = params[i].indexOf('=');
		if (pos > 0) {
			var key = params[i].substring(0,pos);
			var val = params[i].substring(pos+1);
			paramObj[key] = val;
		}
	}
	return paramObj;
}
//GETパラメータを取得
//var qsParam = new Object();
var queryStr = '';
var hashStr = '';
function retrieveGETqs() {
	if (1 < window.location.search.length) {
		//受け取ったクエリ文字列の先頭の'?'を取ってそのまま使う
		queryStr = window.location.search.substring(1);
		//連想配列に入れたい場合はqsParamの変数定義と以下をアンコメント
//		var query = window.location.search.substring(1);
//		var params = query.split('&');
//		for (var i=0; i<params.length; i++) {
//			var pos = params[i].indexOf('=');
//			if (pos > 0) {
//				var key = params[i].substring(0,pos);
//				var val = params[i].substring(pos+1);
//				qsParam[key] = val;
//			}
//		}
	}
	if (1 < window.location.hash.length) {
		//IEでローカルファイルにクエリ文字列が使えないのでフラグメント識別子を代わりに使う
		hashStr = window.location.hash.substring(1);
	}
}
var swfNameStr = '';
//swf読み込み部分を出力
function swfView(clsid, swfname, width, height, bgcolor, params) {
	var isMSIE = /*@cc_on!@*/false;
	retrieveGETqs();
	var paramstr = params;
	if (queryStr != '') paramstr += ((paramstr.length > 0) ? '&amp;' : '') + escapeHTML(queryStr);
	if (hashStr != '') paramstr += ((paramstr.length > 0) ? '&amp;' : '') + escapeHTML(hashStr);
// 連想配列で処理したい場合は以下をアンコメント
//	for (var                                                                                                         prop in params) {
//		if (paramstr != '') paramstr += '&amp;';
//		paramstr += prop + '=' + escapeHTML(params[prop]);
//	}
//	for (var prop in qsParam) {
//		if (paramstr != '') paramstr += '&amp;';
//		paramstr += prop + '=' + escapeHTML(qsParam[prop]);
//	}

	function makeObjParamStr() {
		return '<param name="movie" value="' + escapeHTML(swfname) + '.swf" />'
				+ '<param name="quality" value="high" />'
				+ '<param name="bgcolor" value="' + bgcolor + '" />'
				+ '<param name="play" value="true" />'
				+ '<param name="loop" value="true" />'
				+ '<param name="wmode" value="window" />'
				+ '<param name="scale" value="showall" />'
				+ '<param name="menu" value="true" />'
				+ '<param name="devicefont" value="false" />'
				+ '<param name="salign" value="" />'
				+ '<param name="allowScriptAccess" value="sameDomain" />'
				+ '<param name="allowFullScreen" value="true" />'
				+ '<param name="FlashVars" value="' + paramstr + '" />';
	}

	swfNameStr = swfname;
	var elm = document.getElementById('flashContent');
	var insertHtml = '<object classid="clsid:' + clsid + '" width="' + width + '" height="' + height + '" id="external' + escapeHTML(swfname) + '" align="middle">';
	insertHtml += makeObjParamStr();
	if (!isMSIE) {
		insertHtml += '<object type="application/x-shockwave-flash" data="' + escapeHTML(swfname) + '.swf" width="' + width + '" height="' + height + '">';
		insertHtml += makeObjParamStr();
	}
	insertHtml += '<a href="http://www.adobe.com/go/getflash">';
	insertHtml += '<img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Adobe Flash Player を取得" />';
	insertHtml += '</a>';
	if (!isMSIE) {
		insertHtml += '</object>';
	}
	insertHtml += '</object>';
	elm.insertAdjacentHTML('beforeend', insertHtml);
}

function DocumentGetFlashPlayerElementById(document_obj,id){
	var element = document_obj.getElementById(id);
	if(!element) return null;
	//IE11は内側のobject
	if(document_obj.documentMode && document_obj.documentMode != 11) return element;

	var nodes = element.getElementsByTagName("embed");
	if(nodes.length){
		return nodes[nodes.length-1];
	}

	var nodes = element.getElementsByTagName("object");
	if(nodes.length){
		return nodes[nodes.length-1];
	}

	return element;
}

function hashChangeHandler() {
	var hashStr = '';
	if (1 < window.location.hash.length) {
		hashStr = window.location.hash.substring(1);
	}
	var param = qstrToObj(hashStr);
	if ((typeof param['sttime'] !== 'undefined') && (typeof param['edtime'] !== 'undefined')) {
		DocumentGetFlashPlayerElementById(document, 'external' + swfNameStr).setPlayRange(param['sttime'], param['edtime']);
	}
}

document.addEventListener("DOMContentLoaded", function(e) {
	window.addEventListener("hashchange", hashChangeHandler, false);
}, false);
