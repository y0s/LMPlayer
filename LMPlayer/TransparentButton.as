// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import flash.display.*;
	import flash.events.*;
	import BookmarkItem;

	/**
	 * 透明ボタンクラス.
	 * 
	 * <p>透明なボタン。クリッカブルマップのクリック領域として配置して使う。</p>
	 */
	public class TransparentButton extends SimpleButton
	{
		/** 対応するしおり情報 */
		public var bkmk:BookmarkItem;
		
		/** ヒット領域の幅 */
		const HITAREA_WIDTH:Number = 100;
		/** ヒット領域の高さ */
		const HITAREA_HEIGHT:Number = 100;

		/**
		 * サイズと位置を設定し、しおりデータを持たせる。
		 * 
		 * @param	x1	左上x座標
		 * @param	y1	左上y座標
		 * @param	x2	右下x座標
		 * @param	y2	右下y座標
		 * @param	bk	しおりデータ
		 */
		public function setup(x1:Number, y1:Number, x2:Number, y2:Number, bk:BookmarkItem):void
		{
			this.x = x1;
			this.y = y1;
			this.scaleX = (x2 - x1) / HITAREA_WIDTH;
			this.scaleY = (y2 - y1) / HITAREA_HEIGHT;
			bkmk = bk;
		}
		
		/**
		 * コンストラクタ.
		 */
		public function TransparentButton()
		{
		}
	}
}