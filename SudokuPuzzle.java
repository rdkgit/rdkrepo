/* SudokuPuzzle.java

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

/** Sudoku puzzle solver
   @author Bobby Krupczak, rdk@krupczak.org
   @version $Id: SudokuPuzzle.java 16 2008-07-21 14:12:38Z rdk $
**/

public class SudokuPuzzle {

   /* class variables and methods *********************** */

   /* instance variables ******************************** */
   int size;
   int quadSize;
   int[][] elements;   // [1..rows..size][1..colunns..size] */

   /* constructors  ************************************* */
   SudokuPuzzle(int sz) 
   { 
        int i,j;

        size = sz;

        quadSize = (int)Math.sqrt(sz);
 
        elements = new int[sz+1][sz+1];
        for (i=0; i<=size; i++) {
            for (j=0; j<=size; j++) {
                elements[i][j] = 0;
            }
        }

   }

   /* private methods *********************************** */

   // solve for given position
   private boolean solvePosition(int row, int column)
   {
        int i;
        boolean b;
        int newColumn, newRow;

        //System.out.println("Solving position "+row+","+column);

        // check fenceposts
        if ((row < 1) || (row > size)) {
	   System.out.println("Row "+row+" out of bounds");
           System.exit(-1);
        }
        if ((column < 1) || (column > size)) {
	   System.out.println("Column "+column+" out of bounds");
           System.exit(-1);
        }

        // if the value is already pre-set, go on to next element
        if (elements[row][column] != 0) {
            //System.out.println(row+","+column+" already has value("+
	    //                elements[row][column]+")");
	    // advance to next value
	    newRow = row;
	    newColumn = column+1;

            if (newColumn > size) {
		newColumn = 1;
		newRow++;
                /* if we've finished, return true */
                if (newRow > size) {
		    //System.out.println("Reached size/size");
	           return true;
                }
	    }

            return solvePosition(newRow,newColumn);
        }

        // element does not have value; cycle through the 
        // potential values and try them out

        b = false;
        i = 0;

        while ((i < size) && (b == false)) {

            i++;

            //System.out.println("solvePosition: examining "+i+" "+b);

            if (isValidValue(row,column,i) == true) {
	       setValue(row,column,i);

               //System.out.println("Trying ("+row+","+column+")="+i);

	       // advance to next value
	       newRow = row;
	       newColumn = column+1;

               if (newColumn > size) {
		  newColumn = 1;
		  newRow++;
                  /* if we've finished, return true */
                  if (newRow > size) {
		      //System.out.println("Reached size/size in trials");
	             return true;
                  }
               }

	       b = solvePosition(newRow,newColumn);

               if (b == false) {
		   //System.out.println("resetting value at "+row+","+column);
	          setValue(row,column,0);
               }

	    } /* if valid value */

        } /* while trying out values and false */

        //System.out.println("At end of solvePosition");

        // couldnt find a value that fits in this position */
        return b;
   }

   // given a value and location, is value OK? */

   // for sudoku puzzles: 
   //   every row has to have every digit exactly once
   //   every column has to have each digit exactly once
   //   every quadrant has to have each digit exactly once 

   private boolean isValidValue(int row, int column, int value)
   {
        int i,j;
        int quadRow, quadColumn;

        if ((row < 1) || (row > size)) {
	   System.out.println("isValidValue: row out of bounds");
           System.exit(-1);
        }
        if ((column < 1) || (column > size)) {
	   System.out.println("isValidValue: column out of bounds");
           System.exit(-1);
        }

        // check the row first
        for (i=1; i<=size; i++) {
            if (elements[row][i] == value)
	       return false;

        }

        // check column next
        for (i=1; i<=size; i++) {
            if (elements[i][column] == value)
	       return false;

        }

        // check quadrant for duplicate value
        // we should be able to figure this out mathematically 

        int startRow = 7;
        int startColumn = 7;

        if (row <= 6)
	   startRow = 4;
        if (row <= 3)
	   startRow = 1;

        if (column <= 6)
	   startColumn = 4;
        if (column <= 3)
	   startColumn = 1;

        for (i=startRow; i<=startRow+2; i++) {
            for (j=startColumn; j<=startColumn+2; j++)
                if (elements[i][j] == value)
		    return false;
        }

        return true;

   }

   /* public methods ************************************ */

   public int getSize() { return size; }

   // set row of elements
   public void setRow(int row, int[] rowValues)
   {
        int i;

        if ((row < 1) || (row > size))
	   return;

        for (i=1; i<=size; i++)
            setValue(row,i,rowValues[i]);
   }

   public void setElements(int[][] newElements)
   {
        int i,j;

        if (newElements.length != size) {
	   return;
	}

        for (i=1; i<=size; i++) 
            for (j=1; j<=size; j++)
                elements[i][j] = newElements[i-1][j-1];

   }

   // set value for row/column; no checking is done
   public void setValue(int row, int column, int value)
   {
        if ((row < 1) || (column < 1)) {
	   System.out.println("setValue: out of bounds");
           System.exit(-1);
        }
        if ((row > size) || (column > size)) {
	   System.out.println("setValue: out of bounds");
           System.exit(-1);
        }
  
        elements[row][column] = value;
   }

   public void printElements()
   {
        int i,j;

        for (i=1; i<=size; i++) {
            for (j=1; j<=size; j++) {
                System.out.print(elements[i][j]+" ");
            }
            System.out.println("");
        }
   }

   public int[][] getElements() { return elements; }

   // main method 
   public boolean solvePuzzle()
   {
        int i,j;
        boolean b;

        return solvePosition(1,1);

   } /* solvePuzzle */

} /* class SudokuPuzzle */
