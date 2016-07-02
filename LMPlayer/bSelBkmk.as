// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import fl.controls.List;
	import flash.display.*;
	import flash.events.*;
	import flash.text.TextField;
	import RadioButtonBase;

	/**
	 * しおりリスト選択ボタンクラス.
	 * 
	 * <p>ラジオボタンがベース。</p>
	 * <p>ボタンと関連付けてしおりリスト、または、しおりクリッカブルマップを保持し、
	 * ボタンの選択状態に対応してしおりリスト･しおりクリッカブルマップの表示状態を変化させる。</p>
	 */
	public class bSelBkmk extends RadioButtonBase
	{
		/** しおりリスト番号表示部 */
		public var btnlabel:TextField;
		/**
		 * ボタンと関連付けるしおりリスト／しおりクリッカブルマップ
		 */
		protected var targetObj: DisplayObject;

		/**
		 * ボタンOn時にコールされ、ボタンと関連付けたリストまたはクリッカブルマップを表示する。
		 * 
		 * @param	noaction	動作を行わずボタンの表示状態のみ変更させる場合trueにする。
		 */
		override public function setOn(noaction:Boolean=false):void
		{
			if (!noaction && targetObj) {
				targetObj.visible = true;
			}
			super.setOn(noaction);
		}
		
		/**
		 * ボタンOff時にコールされ、ボタンと関連付けたリストまたはクリッカブルマップを非表示にする。
		 * 
		 * @param	noaction	動作を行わずボタンの表示状態のみ変更させる場合trueにする。
		 */
		override public function setOff(noaction:Boolean=false):void
		{
			if (!noaction && targetObj) {
				targetObj.visible = false;
			}
			super.setOff(noaction);
		}

		/**
		 * 対象となるしおりリスト／クリッカブルマップを設定する.
		 * 
		 * @param	obj	リストまたはクリッカブルマップ
		 */
		public function setTarget(obj: DisplayObject):void
		{
			targetObj = obj;
		}
		
		/**
		 * ラベルの書式変更を伴う、ボタンの再生ヘッドの移動.
		 * 
		 * <p>フレームアクションで書式を設定してもよかったが、タイムライン上にスクリプトを書いたり、
		 * 非公開の<code>addFrameScript()</code>を使うのは避けたかったので、
		 * <code>gotoAndStop()</code>をオーバーライドすることにした。</p>
		 * 
		 * @param	frame	移動先フレーム
		 * @param	scene	移動先シーン
		 */
		override public function gotoAndStop(frame:Object, scene:String = null):void
		{
			switch (frame as String) {
			case onLabel:
				btnlabel.textColor = 0xffffff;
				break;
			case offLabel:
				btnlabel.textColor = 0;
				break;
			}
			super.gotoAndStop(frame, scene);
		}
		
		/**
		 * コンストラクタ
		 */
		public function bSelBkmk()
		{
		}
	}
}