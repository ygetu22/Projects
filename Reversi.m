clc
clear
close all

% sprite file name
spriteFile = "SpriteSheet.png";

% All sprites are 16x16 pixels
spriteDim_X = 16; 
spriteDim_Y = 16;

% sprite scaling stats
spriteScale = 10;

% white background
backgroundColor = [255, 255, 255]; 

% simpleGameEngine object
reversiScene = simpleGameEngine(spriteFile, spriteDim_X, spriteDim_Y, ...
    spriteScale, backgroundColor);

% 'square/box' sprite, 'black tile' sprite, 'white tile' sprite
backgroundSpriteIDs = [2, 9, 10];

% borderSprites used to create border box
borderSprites = 3:8;

% gameState 1 background data (does not change)
sceneBackground = ones(10, 16);

% game board box
sceneBackground = addBorderBox(sceneBackground, 1, 10, 1, 10, borderSprites);
sceneBackground(2:9, 2:9) = backgroundSpriteIDs(1);

% turn/score box
sceneBackground = addBorderBox(sceneBackground, 1, 6, 11, 16, borderSprites);
sceneBackground(2, 12:15) = getCharSprite('turn');
sceneBackground(4, 12) = backgroundSpriteIDs(2);
sceneBackground(5, 12) = backgroundSpriteIDs(3);
sceneBackground([4 5], 13) = getCharSprite(':');

% menu icon box
sceneBackground = addBorderBox(sceneBackground, 8, 10, 11, 16, borderSprites);
sceneBackground(9, 12:15) = getCharSprite('menu');

% gameState 1 scene data
sceneMenu = ones(11, 9);
sceneMenu = addBorderBox(sceneMenu, 1, 11, 1, 9, borderSprites);

sceneMenu = addBorderBox(sceneMenu, 2, 4, 2, 8, borderSprites);
sceneMenu(3, 4:6) = getCharSprite('end');

sceneMenu = addBorderBox(sceneMenu, 5, 7, 2, 8, borderSprites);
sceneMenu(6, 3:7) = getCharSprite('reset'); 

sceneMenu = addBorderBox(sceneMenu, 8, 10, 2, 8, borderSprites);
sceneMenu(9, 3:7) = getCharSprite('close'); 

% gameState 0 data that changes as game is played
sceneGame = ones(10, 16);
[boardData, scoreData, turnData] = resetGame();

% scene handling
sceneRunning = true;
gameState = 0;

%{
% "empty" sprite, "black tile" sprite, "white tile" sprite, 
% "possible black move" sprite, "possible white move" sprite
%}
spriteIDs = [1, 9, 10, 11, 12];

while sceneRunning
    switch gameState
        case 0
            % game
            sceneGame = getScene(boardData, scoreData, ...
                turnData, spriteIDs);
            drawScene(reversiScene, sceneBackground, sceneGame);
            xlabel("Click anywhere to interact.");
            % game win state
            if turnData(2) == 0
                bScore = scoreData(1);
                wScore = scoreData(2);
                if bScore > wScore
                    xlabel("Black Wins!");
                elseif bScore < wScore
                    xlabel('White Wins!');
                else
                    xlabel("Draw!");
                end
            end
        
            [clickedRow, clickedCol] = getMouseInput(reversiScene);
            
            % adjustment for board starting at (2, 2) rather than (1, 1)
            clickedX = clickedRow - 1;
            clickedY = clickedCol - 1;

            
            if isValidMove(boardData, turnData(2), clickedX, clickedY)
                % Check if clicked area is a valid move

                % updates board, score, turn data
                [boardData, scoreData, turnData] = updateData(boardData, ...
                    turnData, clickedX, clickedY);

            elseif clickedRow == 9 && clickedCol <= 15 && clickedCol >= 12
                % check if menu is clicked
                gameState = 1;
            end
        case 1
            % menu
            drawScene(reversiScene, sceneMenu);
            xlabel("Click anywhere to interact.");

            [clickedRow, clickedCol] = getMouseInput(reversiScene);

            if clickedCol >= 3 && clickedCol <= 7
                switch clickedRow
                    case 3
                        % end button
                        gameState = 2;
                    case 6
                        % reset button
                        gameState = 0;
                        [boardData, scoreData, turnData] = resetGame();
                    case 9
                        % close button
                        gameState = 0;
                end
            end
        case 2
            % close game
            close(1);
            sceneRunning = false;
        otherwise
            disp('Unknown gamestate.');
    end
end

%{
% Returns default board, score, and turn data.
%}
function [newBoard, newScore, newTurn] = resetGame()
    newBoard = zeros(8);
    newBoard(4, 4:5) = [2 1];
    newBoard(5, 4:5) = [1 2];
    newScore = [2 2];
    newTurn = [1 1];
end


%{
% Checks if board coordinate would be within bounds.
%}
function inBounds = inBounds(x, y)
    inBounds = (x >= 1) & (x <= 8) & (y >= 1) & (y <= 8);
end

%{
% Checks if space on board is a specific tile.
%}
function isTile = checkSpace(board, tile, x, y)
    isTile = inBounds(x, y) && (board(x, y) == tile);
end

%{
% Gets tile corresponding to the opponent.
%}
function oppTile = getOppTile(tile)
    oppTile = (-1 * tile) + 3;
end

%{
% Gets maximum number of tiles needed to be checked based on direction
% checked and starting space.
%}
function maxChecks = getMaxChecks(x, y, dirX, dirY)
    switch dirX
        case -1
            maxXChecks = x - 1;
        case 0
            maxXChecks = 7;
        case 1
            maxXChecks = 8 - x;
    end
    switch dirY
        case -1
            maxYChecks = y - 1;
        case 0
            maxYChecks = 7;
        case 1
            maxYChecks = 8 - y;
    end
    maxChecks = min(maxXChecks, maxYChecks);
end

%{
% Checks how many tiles are captured from an initial board space and in
% a specific direction.
%}
function capturedTiles = checkDir(board, tile, x, y, dirX, dirY)
    capturedTiles = 0;
    maxChecks = getMaxChecks(x, y, dirX, dirY);
    for i = 1:maxChecks
        switch board(x + dirX * i, y + dirY * i)
            case 0
                return;
            case tile
                capturedTiles = i - 1;
                return;
        end
    end
end

%{
% Resolves tiles to be flipped in a direction.
%}
function newBoard = resolveDir(board, tile, x, y, dirX, dirY)
    newBoard = board;
    capturedTiles = checkDir(board, tile, x, y, dirX, dirY);
    for i = 1:capturedTiles
        newBoard(x + dirX * i, y + dirY * i) = tile;
    end
end

%{
% Checks if a board space would be a valid move for a tile.
%}
function isValid = isValidMove(board, tile, x, y)
    isValid = false;
    xDirs = [-1 -1 -1 0 0 1 1 1];
    yDirs = [-1 0 1 -1 1 -1 0 1];
    % check if space is empty and is within bounds
    if checkSpace(board, 0, x, y)
        for i = 1:length(xDirs)
            capturedTiles = checkDir(board, tile, x, y, xDirs(i), yDirs(i));
            if capturedTiles > 0
                isValid = true;
                break;
            end
        end
    end
end

%{
% Flips tiles based on move and adds tile to board.
%}
function newBoard = resolveMove(board, tile, x, y)
    newBoard = board;
    newBoard(x, y) = tile;
    xDirs = [-1 -1 -1 0 0 1 1 1];
    yDirs = [-1 0 1 -1 1 -1 0 1];
    for i = 1:length(xDirs)
        newBoard = resolveDir(newBoard, tile, x, y, xDirs(i), yDirs(i));
    end
end

%{
% Calculates score for both players.
%}
function newScore = calculateScore(board)
    bScore = sum(board == 1, "all");
    wScore = sum(board == 2, "all");
    newScore = [bScore wScore];
end

%{
% Checks if player (tile) has any possible move
%}
function canMove = hasValidMove(board, tile)
    canMove = false;
    for row = 1:8
        for col = 1:8
            if isValidMove(board, tile, row, col)
                canMove = true;
                return;
            end
        end
    end
end

%{
% Returns new turn data.
%}
function newTurn = updateTurn(board, turn)
    currPlayer = turn(2);
    nextPlayer = getOppTile(currPlayer);
    if hasValidMove(board, nextPlayer)
        newTurn = [turn(1) + 1, nextPlayer];
    elseif hasValidMove(board, currPlayer)
        newTurn = [turn(1) + 1, currPlayer];
    else
        newTurn = [turn(1), 0];
    end
end

%{
% Gets new board, score, and turn data based on the move being played
%}
function [newBoard, newScore, newTurn] = updateData(board, turn, x, y)
    currPlayer = turn(2);
    newBoard = resolveMove(board, currPlayer, x, y);
    newScore = calculateScore(newBoard);
    newTurn = updateTurn(newBoard, turn);
end

%{
% Returns board with possible moves.
%}
function moveBoard = getMoveBoard(board, tile)
    moveBoard = board;
    for row = 1:8
        for col = 1:8
            if isValidMove(board, tile, row, col)
                moveBoard(row, col) = tile + 2;
            end
        end
    end
end

%{
% Generates spriteID equivalent of moveBoard.
%}
function gameBoard = convertMoveBoard(moveBoard, spriteIDs)
    gameBoard = spriteIDs(moveBoard + 1);
end

%{
% Converts number to char equivalent but prepends a 0 if the number is
% a single-digit number.
%}
function charNum = convertNumToChars(num)
    strNum = string(num);
    if (strlength(strNum) == 1)
        strNum = append("0", strNum);
    end
    charNum = char(strNum);
end

%{
% Gets what the user should see (sceneGame) based on board, score, turn data.
%}
function newSceneGame = getScene(board, score, turn, spriteIDs)
    newSceneGame = ones(10, 16);
    currTurn = turn(1);
    currPlayer = turn(2);
    moveBoard = getMoveBoard(board, currPlayer);
    newSceneGame(2:9, 2:9) = convertMoveBoard(moveBoard, spriteIDs);

    turnChar = convertNumToChars(currTurn);
    bScoreChar = convertNumToChars(score(1));
    wScoreChar = convertNumToChars(score(2));

    % turn indicator
    newSceneGame(3, [12 15]) = spriteIDs(currPlayer + 1); 
    newSceneGame(3, [13 14]) = getCharSprite(turnChar); % turn counter
    newSceneGame(4, [14 15]) = getCharSprite(bScoreChar); % b score
    newSceneGame(5, [14 15]) = getCharSprite(wScoreChar); % w score
end

%{
% sceneBG is the current background scene to add a border box to
% startRow, endRow, startCol, endCol define where the box should be
% the vertical sides of the box will be at startCol and endCol
% borderSpriteIDs should contain sprite ids (in order) for:
% [top left border, top right corner, vertical border, horizontal 
% border, bottom left border, bottom right border]
%}
function newSceneBG = addBorderBox(sceneBG, startRow, endRow, startCol, endCol, borderSpriteIDs)
    newSceneBG = sceneBG;
    rowRange = (startRow + 1):(endRow - 1);
    colRange = (startCol + 1):(endCol - 1);

    newSceneBG(startRow, startCol) = borderSpriteIDs(1);
    newSceneBG(startRow, endCol) = borderSpriteIDs(2);

    newSceneBG(rowRange, [startCol endCol]) = borderSpriteIDs(3);
    newSceneBG([startRow endRow], colRange) = borderSpriteIDs(4);

    newSceneBG(endRow, startCol) = borderSpriteIDs(5);
    newSceneBG(endRow, endCol) = borderSpriteIDs(6);
end

%{
% Gets spriteID for characters if it exists in the spritesheet.
% Otherwise returns spriteID for empty sprite.
%}
function spriteID = getCharSprite(charVar) 
    % gets char value
    charAscii = double(charVar);
    % columns in spritesheet
    totCols = 13;

    % converts 'a-z' to 'A-Z'
    if charAscii >= 97 & charAscii <= 122
        charAscii = charAscii - 32;
    end

    if charAscii >= 48 & charAscii <= 57
        % '0-9' sprites
        initRow = 2; shift = charAscii - 47;

    elseif charAscii >= 65 & charAscii <= 90
        % 'A-Z' sprites, some are in 4th row
        initRow = 3; shift = charAscii - 64;

    elseif charAscii == 58
        % ':' sprite
        initRow = 2; shift = 11;

    elseif charAscii == 46
        % '.' sprite (unused)
        initRow = 2; shift = 12;

    elseif charAscii == 37
        % '%' sprite (unused)
        initRow = 2; shift = 13;

    else
        % defaults to empty sprite
        initRow = 1; shift = 1;
    end

    % calculates spriteID
    spriteID = totCols * (initRow - 1) + shift;
end
