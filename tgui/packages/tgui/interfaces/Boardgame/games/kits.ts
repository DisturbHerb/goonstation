import { GameKit } from '.';
import chessKit from './chess';
import draughtsKit from './draughts';
import xiangqiKit from './xiangqi';

// Add new kits here

export type GameName = 'chess' | 'draughts' | 'xiangqi';

export const kits: GameKit[] = [chessKit, draughtsKit, xiangqiKit];
