// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import flash.display.*;
	import flash.events.*;
	import ToggleButtonBase;


	/**
	 * ラジオボタンクラス.
	 * 
	 * <p>クリックすると選択状態が切り替わるボタン。つねに1個のみが選択される。
	 * 同一グループに属するボタンを管理するために、 Array 型の配列を用意し、 <code>attachTo()</code> を実行すること。</p>
	 * 
	 * <p>ボタンとするMovieClipは、以下のフレームを持つ。</p>
	 * <ul>
	 * <li>フレーム "l_on" にOn状態のデザイン。</li>
	 * <li>フレーム "l_off" にOff状態のデザイン。</li>
	 * <li>フレーム "l_over" にマウスオーバー時のデザイン。(オプション)</li>
	 * <li>hasDisableImage を true に設定した場合は、フレーム "l_disable" が機能無効時のデザインとして使われる。</li>
	 * </ul>
	 */
	public class RadioButtonBase extends ToggleButtonBase
	{
		/**
		 * ボタンのグループの管理配列(先頭に現在選択されている要素の番号が入る)
		 */
		protected var btnArray: Array;

		/**
		 * btnArrayの何番目の要素か
		 */
		protected var arrIndex: Number;
		
		/**
		 * それまで選択されていたボタンを非選択状態にし、このボタンを選択状態にする。
		 * 
		 * @param	noaction	true にすると、 onFunction や offFunction を実行しない。
		 */
		override public function setOn(noaction:Boolean=false):void
		{
			btnArray[btnArray[0]].setOff(noaction);
			btnArray[0] = arrIndex;
			super.setOn(noaction);
		}

		/**
		 * 非選択状態のボタンがクリックされた場合に選択状態にする。
		 * 
		 * @param	event	イベントオブジェクト
		 */
		override protected function clickHandler(event:MouseEvent):void
		{
			if (onOffState) {
			} else {
				setOn();
			}
		}

		/**
		 * ボタンをグループに所属させる.
		 * 
		 * @param	arr	グループを管理する配列
		 */
		public function attachTo(arr: Array):void
		{
			btnArray = arr;
			if (btnArray.length == 0) {
				btnArray.push(0);
			}
			arrIndex = btnArray.push(this);
			--arrIndex;
			if (arrIndex == 1) {
				btnArray[0] = arrIndex;
				super.setOn();
			} else {
				setOff();
			}
		}

		/**
		 * コンストラクタ.
		 */
		public function RadioButtonBase()
		{
		}
	}
}