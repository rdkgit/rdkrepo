/* GraphCellComparator.java

   COPYRIGHT 2008 KRUPCZAK.ORG, LLC.

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

package org.krupczak.Cartographer;

import java.util.Comparator;
import org.jgraph.JGraph;
import org.jgraph.graph.*;
import com.jgraph.layout.JGraphFacade;

/** 
 * Compare two graph verticies; we can compare based on different
 * properties depending on the compareMetric value.  Default is to
 * compare based on number of neighbors
 * @author Bobby Krupczak, rdk@krupczak.org
 * @version $Id: GraphCellComparator.java 42 2008-08-04 02:09:23Z rdk $
 **/

public class GraphCellComparator implements Comparator {

   /* class variables and methods *********************** */
   public static int COMPARE_EDGES = 1;
   public static int COMPARE_NEIGHBORS = 2;

   /* instance variables ******************************** */
   public int compareMetric;
   public JGraphFacade theFacade;

   /* constructors  ************************************* */
   GraphCellComparator() 
   { 
       compareMetric = COMPARE_NEIGHBORS;
       return; 
   }

   GraphCellComparator(JGraphFacade f, int compareMetric) 
   { 
       this.compareMetric = compareMetric;
       this.theFacade = f;

       if ((this.compareMetric < COMPARE_EDGES) || 
	   (this.compareMetric > COMPARE_NEIGHBORS))
           this.compareMetric = COMPARE_NEIGHBORS;

       return; 
   }

   /* private methods *********************************** */

   /* public methods ************************************ */

   public int getCompareMetric() { return compareMetric; }
   public void setCompareMetric(int compareMetric)
   {
       this.compareMetric = compareMetric;

       if ((this.compareMetric < COMPARE_EDGES) || 
	   (this.compareMetric > COMPARE_NEIGHBORS))
           this.compareMetric = COMPARE_NEIGHBORS;

       return; 
   }

   public int compare(Object a, Object b)
   {
       DefaultGraphCell a1, b1;

       // dig out the verticies       
       a1 = (DefaultGraphCell)a;
       b1 = (DefaultGraphCell)b;

       if (compareMetric == COMPARE_EDGES) {
	   return theFacade.getEdges(b1).length - 
	          theFacade.getEdges(a1).length;
       }
       else {
	  // compare number of neighbors
	  return theFacade.getNeighbours(b1,false).size() -
	         theFacade.getNeighbours(a1,false).size();
       }
   }

} /* class GraphCellComparator */
