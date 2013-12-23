/* TestSudoku.java

   COPYRIGHT 2006 KRUPCZAK.ORG, LLC.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
   USA
 
   For more information, visit:
   http://www.krupczak.org/
*/

/**
   TestSudoku puzzle solver
   @author Bobby Krupczak, rdk@krupczak.org
   @version $Id: TestSudoku.java 16 2008-07-21 14:12:38Z rdk $
   @see SudokuPuzzle
   @see Sudoku
**/

public class TestSudoku {

   /* class variables and methods *********************** */
   private static void usage(String argv[]) {
	System.out.println("Usage: java TestSudoku");
        System.exit(-1);
   }

   public static void main(String argv[])
   {
       SudokuPuzzle thePuzzle;

       thePuzzle = new SudokuPuzzle(9);

       System.out.println("TestSudoku starting with size "
                          +thePuzzle.getSize());

       int[][] elements = {

           { 0,5,7,4,9,0,0,0,0 }, 
           { 9,0,4,2,0,1,3,5,0 },
           { 0,0,6,8,0,5,0,0,9 },
           { 0,6,0,0,0,3,0,7,5 },
           { 5,0,2,7,0,4,8,0,3 },
           { 1,7,0,5,0,0,0,6,0 },
           { 6,0,0,9,0,8,2,0,0 },
           { 0,2,1,3,0,7,6,0,4 },
           { 0,0,0,0,4,2,5,8,0 },

       };

       int[][] elements1 = {

           { 2,0,0,0,4,6,0,0,3 },
           { 0,0,0,5,7,0,2,4,8 },
           { 4,8,0,0,0,2,5,0,7 },
           { 3,0,7,0,2,8,0,0,4 },
           { 0,1,0,0,0,0,0,2,0 },
           { 6,0,0,4,5,0,7,0,9 },
           { 7,0,1,2,0,0,0,9,5 },
           { 8,3,6,0,9,5,0,0,0 },
           { 9,0,0,7,6,0,0,0,1 },

       };

       thePuzzle.setElements(elements1);

       System.out.println("Going to solve puzzle: ");

       thePuzzle.printElements();

       if (thePuzzle.solvePuzzle() == true) {
          System.out.println("Solution: ");
	  thePuzzle.printElements();
       }
       else {
	  System.out.println("Puzzle is not solvable");
          thePuzzle.printElements();
       }

   }

   /* instance variables ******************************** */

   /* constructors  ************************************* */

   /* private methods *********************************** */

   /* public methods ************************************ */

} /* class TestSudoku */
