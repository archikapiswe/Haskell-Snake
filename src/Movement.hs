module Movement where

import Types

import Lens.Micro   ((^.), (&), (.~), (%~))
import Test.QuickCheck
import Brick.Types
import Brick
import Control.Monad.IO.Class

gameHandler :: GameState -> EventM n (Next GameState)
gameHandler gs = case gs ^. (gsSnakeL . sHeadL) of
  pos | pos == gs ^. gsFoodPosL                       -> foodPosHandler gs
  pos | elem pos $ drop 1 (gs ^. (gsSnakeL . sTailL))  -> strikeHandler gs 
  (Cord x y) | x == 1 + fst (gs ^. gsSizeL) || x < 0     -> strikeHandler gs
  (Cord x y) | y == 1 + snd (gs ^. gsSizeL) || y < 0     -> strikeHandler gs 
  anythingElse -> do  
    let snHead   = gs ^. (gsSnakeL . sHeadL)
        snTail   = gs ^. (gsSnakeL . sTailL)
        snDir    = gs ^. (gsSnakeL . sDirL)
        newSHead = getNextCord snHead snDir
        newSnake = Snake newSHead (init $ snHead:snTail) snDir
    continue $ gs & gsSnakeL .~ newSnake 

foodPosHandler :: GameState -> EventM n (Next GameState)
foodPosHandler gs = do
  let snHead      = gs ^. (gsSnakeL . sHeadL)
      snTail      = gs ^. (gsSnakeL . sTailL)
      snDir       = gs ^. (gsSnakeL . sDirL)
      foodPos     = gs ^. gsFoodPosL
      gridSize    = gs ^. gsSizeL
      newSnake    = Snake foodPos (snHead : snTail) snDir
      snakeCords  = snHead : snTail
  newFoodPos <- liftIO $ genFoodPos gridSize snakeCords
  continue $ gs & (gsSnakeL .~ newSnake).(gsFoodPosL .~ newFoodPos).(gsFoodCountL %~ (+1)).(gsScoreL %~ (+10))

strikeHandler :: GameState -> EventM n (Next GameState)
strikeHandler gs = do 
  let lifeCount = gs ^. gsLifeCountL
      newSnake = Snake (Cord 1 7) [Cord 1 6,Cord 1 5] UP
  case lifeCount of
    l | l == 1 -> continue (gs & gsGameStatusL .~ GameOver)
    _ -> continue $ gs & (gsSnakeL .~ newSnake).(gsLifeCountL %~ pred)

getNextCord :: Cordinate -> DIRECTION -> Cordinate
getNextCord (Cord x y) dir = case dir of
    UP    -> Cord (x+1) y
    RIGHT -> Cord x (y+1)
    DOWN  -> Cord (x-1) y
    LEFT  -> Cord x (y-1)

getNextDir :: DIRECTION -> DIRECTION
getNextDir UP = RIGHT
getNextDir DOWN = LEFT
getNextDir RIGHT = UP
getNextDir LEFT = DOWN


turn :: DIRECTION -> GameState -> GameState 
turn dir gs = gs & gsSnakeL %~ setSnakeDir dir'
  where
    oldDir = gs ^. gsSnakeL . sDirL
    dir'   =
      if isOppositeDir dir oldDir 
        then oldDir
        else dir   

isOppositeDir :: DIRECTION -> DIRECTION -> Bool
isOppositeDir UP    DOWN  = True        
isOppositeDir DOWN  UP    = True        
isOppositeDir LEFT  RIGHT = True        
isOppositeDir RIGHT LEFT  = True        
isOppositeDir _     _     = False        

setSnakeDir :: DIRECTION -> Snake -> Snake
setSnakeDir d s = s & sDirL .~ d

genFoodPos :: GameSize -> [Cordinate] -> IO Cordinate
genFoodPos (row,col) snakeCords = do
  x <- generate $ choose (0,row-1)
  y <- generate $ choose (0,col-1)
  let cord = Cord y x
  if Cord y x `elem` snakeCords then genFoodPos (row,col) snakeCords else return (Cord y x)
