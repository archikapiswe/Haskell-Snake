{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module UI where

import qualified Graphics.Vty as V
import qualified Brick.AttrMap as A
import Brick
import Brick.Types
import Brick.Widgets.Core
import Brick.Widgets.Border.Style
import Brick.Widgets.Center
import Graphics.Vty
import Lens.Micro   ((^.), (&), (.~), (%~))

import Types

-- | Takes GameState and renders the required widget
renderGame :: GameState -> Widget ()
renderGame gs = case gs ^. gsGameStatusL of
  Initial  -> drawStartGame gs
  ModeSelect -> drawModeSelect gs
  Playing  -> drawGameObject gs
  Paused -> drawGameObject gs
  GameOver -> drawGameOver gs

-- | Takes GameState and returns the widget for Start Game
drawStartGame :: GameState -> Widget ()
drawStartGame gs = center $ Widget Fixed Fixed $ do
  return $ emptyResult &
    imageL .~ initImg
  where initImg = vertCat [border,nameImg,border,optionsImg,border]
        border = charFill bgColor ' ' 40 1
        nameImg = string bgColor "         ***** HSnake Game *****        "
        optionsImg = vertCat [startImg,border,modeImg]
        startImg = horizCat [charFill bgColor ' ' 2 1,sKey,string bgColor " Start Game                        "]
        sKey = string (getAttr "key") " S "
        modeImg = horizCat [charFill bgColor ' ' 2 1,mKey,string bgColor " Select Mode                       "]
        mKey = string (getAttr "key") " M "
        lightC = charFill (getAttr "lightGreen") ' ' 2 1
        darkC = charFill (getAttr "darkGreen") ' ' 2 1  
        bgColor = getAttr "bgLightGreen"

-- | Takes GameState and returns the widget for Mode Selection
drawModeSelect :: GameState -> Widget ()
drawModeSelect gs = center $ Widget Fixed Fixed $ do
  return $ emptyResult &
    imageL .~ initImg
  where initImg = vertCat [border,titleImg,border,optionsImg,border]
        border = charFill bgColor ' ' 40 1
        titleImg = string bgColor "       ***** Select Game Mode *****     "
        optionsImg = vertCat [normalImg,border,infiniteImg]
        normalImg = horizCat [charFill bgColor ' ' 2 1,sKey,string bgColor " Normal Mode                       "]
        sKey = string (getAttr "key") " 1 "
        infiniteImg = horizCat [charFill bgColor ' ' 2 1,mKey,string bgColor " Infinite Mode                     "]
        mKey = string (getAttr "key") " 2 "
        lightC = charFill (getAttr "lightGreen") ' ' 2 1
        darkC = charFill (getAttr "darkGreen") ' ' 2 1  
        bgColor = getAttr "bgLightGreen"

-- | Takes GameState and returns the Game Widget
drawGameObject :: GameState -> Widget ()
drawGameObject gs = center $ Widget Fixed Fixed $ do
  return $ emptyResult &
    imageL .~ gameImg 
      where gameImg = vertCat [mkScoreImg gs,mkGameImg gs]

-- | Takes GameState and returns the game image accordingly 
mkGameImg :: GameState -> Image
mkGameImg gs = gameImg
      where gameImg = mkHorizBorder.vertCat $ fmap (mkRowImg gs) rowMap
            rowMap = mkRowMap (gsSize gs)

-- | Takes game image and returns the game image with horizontal border
mkHorizBorder :: Image -> Image
mkHorizBorder img = vertCat [border,img,border]
  where
    border = charFill brColor ' ' width 1
    width = imageWidth img
    brColor = getAttr "bgDarkGreen"

-- | Takes GameState and returns game image with vertical border
mkRowImg :: GameState -> [Cordinate] -> Image
mkRowImg gs cords = horizCat [border,rowImg,border]
  where rowImg = horizCat $ fmap (mkCellImg gs) cords
        border = charFill brColor ' ' 2 1
        brColor = getAttr "bgDarkGreen"

-- | Takes GameState and cordinate and returns cell image of that cordinate accordingly
mkCellImg :: GameState -> Cordinate -> Image
mkCellImg gs cord
  | cord == gsFoodPos gs = horizCat [charFill bgColor2 '🍉' 1 1]
  | cord == sHead (gsSnake gs) = string shColor "▦ " 
  | elem cord $ (sTail $ gsSnake gs) = string stColor "▦ "
  | odd (xCord cord) && odd (yCord cord) = charFill bgColor1 ' ' 2 1
  | even (xCord cord) && even (yCord cord) = charFill bgColor1 ' ' 2 1
  | otherwise = charFill bgColor2 ' ' 2 1
  where 
    bgColor1 = getAttr "lightGreen" 
    bgColor2 = getAttr "darkGreen"  
    shColor = flip V.withStyle V.bold $ V.red `on` rgbColor 55 209 52
    stColor = flip V.withStyle V.bold $ V.black `on` rgbColor 55 209 52

-- | Takes Game Size and returns list of rows of cordinates
mkRowMap :: GameSize -> [[Cordinate]]
mkRowMap (row,col) | row < 0 || col < 0 = []
mkRowMap (row,col) = [Cord row n | n <- [0..col]] : mkRowMap (row-1,col) 

-- | Takes GameState and returns the image of Game Data accordingly
mkScoreImg :: GameState -> Image
mkScoreImg gs = scoreImg
  where scoreImg  = vertCat [imgLine1,imgLine2]
        imgLine1  = horizCat [fCountImg,charFill brColor ' ' spCount1 1,lCountImg]
        imgLine2  = horizCat [sCountImg,charFill brColor ' ' spCount2 1 ,levelImg]
        fCountImg = horizCat [charFill brColor ' ' 2 1,charFill brColor '🍉' 1 1,string brColor (show foodCount)]
        lCountImg = horizCat [charFill lColor '♥' lifeCount 1,charFill lColorDim '♥' (3-lifeCount) 1,charFill brColor ' ' 2 1] 
        sCountImg = horizCat [charFill brColor ' ' 2 1,charFill brColor '🌟' 1 1,string brColor (show score)]
        levelImg  = horizCat [string brColor (" Level : "++ show level),charFill brColor ' ' 2 1]
        foodCount = gs ^. gsFoodCountL
        lifeCount = gs ^. gsLifeCountL
        score     = gs ^. gsScoreL
        level     = gs ^. gsLevelL
        spCount1  = if foodCount < 10 then 36 else 35
        spCount2  = case score of
          s | s == 0  -> 29
          s | s < 100 -> 28
          _           -> 27 
        brColor = V.black `on` rgbColor 13 168 10
        lColor = flip V.withStyle V.bold $ V.red `on` rgbColor 13 168 10
        lColorDim = flip V.withStyle V.dim $ V.red `on` rgbColor 13 168 10        

-- | Takes GameState and returns the widget for Game Over 
drawGameOver :: GameState ->  Widget ()
drawGameOver gs = center $ Widget Fixed Fixed $ do
  return $ emptyResult &
    imageL .~ gameOverImg
    where
      gameOverImg = vertCat [border,gameOver,border,gameDataImg,border,msgImg,border]
      border = charFill bgColor ' ' 40 1
      gameOver = string bgColor "           *****GAME OVER*****          "
      gameDataImg = horizCat [foodImg,spaceCount,scoreImg]
      spaceCount = charFill bgColor ' ' (imageWidth border - imageWidth foodImg - imageWidth scoreImg - 2) 1
      foodImg = horizCat [charFill bgColor ' ' 2 1,charFill bgColor '🍉' 1 1,string bgColor (" " ++ show foodCount)]
      scoreImg = horizCat [charFill bgColor '🌟' 1 1,string bgColor (" " ++ show score),charFill bgColor ' ' 2 1]
      foodCount = gs ^. gsFoodCountL
      score = gs ^. gsScoreL
      msgImg = vertCat [newGameImg,border,changeModeImg,border,quitImg]
      newGameImg = horizCat [charFill bgColor ' ' 2 1,enterKeyImg,string bgColor "  Play Again!                  "]
      quitImg = horizCat [charFill bgColor ' ' 2 1,quitKeyImg,string bgColor "  Quit The Game                    "]
      changeModeImg = horizCat [charFill bgColor ' ' 2 1,modeKeyImg,string bgColor "    Change Mode                    "]
      enterKeyImg = string (getAttr "key") " Enter "
      quitKeyImg = string (getAttr "key") " Q "
      modeKeyImg = string (getAttr "key") " M "
      bgColor = getAttr "bgLightGreen"

-- | Takes a string and returns an attribute accordingly 
getAttr :: String ->  Attr
getAttr "darkGreen" = V.black `on` V.rgbColor 55 209 52
getAttr "lightGreen" = V.black `on` V.rgbColor 92 230 90
getAttr "heart" = flip V.withStyle V.bold $ V.red `on` rgbColor 13 168 10
getAttr "bgDarkGreen" = V.black `on` rgbColor 13 168 10
getAttr "bgLightGreen" = flip V.withStyle V.bold $ V.black `on` rgbColor 55 209 52
getAttr "key" = flip V.withStyle V.bold $ V.black `on` rgbColor 222 221 153
getAttr _ = V.black `on` V.black

-- | Map of Attributes to be used when rendering
theMap::A.AttrMap
theMap = A.attrMap V.defAttr []
