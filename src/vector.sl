% This routine implements some 3-vector operations.
% Copyright (c) 2004-2006 John E. Davis
% You may distribute this file under the terms the GNU General Public
% License.  See the file COPYING for more information.
% 
% Version 0.1.0

if (0 == is_defined ("Vector_Type")) typedef struct
{
   x,y,z
} 
Vector_Type;

private define convert_to_floating (x)
{
   if (_typeof (x) == Float_Type)
     return x;
   return typecast (x, Double_Type);
}

define vector (x,y,z)
{
   variable v = @Vector_Type;
   v.x = convert_to_floating (x);
   v.y = convert_to_floating (y);
   v.z = convert_to_floating (z);
   return v;
}

define dotprod (a,b)
{
   return a.x*b.x + a.y*b.y + a.z*b.z;
}

define crossprod (a,b)
{
   variable ax=a.x,ay=a.y,az=a.z,bx=b.x,by=b.y,bz=b.z;
   return vector (ay*bz-by*az, az*bx-bz*ax, ax*by-bx*ay);
}

define vector_sqr (v)
{
   return dotprod (v,v);
}

define vector_norm (v)
{
   return sqrt (vector_sqr (v));
}

define normalize_vector (v)
{
   variable len = vector_norm (v);
   v.x /= len;
   v.y /= len;
   v.z /= len;
}

define unit_vector (v)
{
   v = @v; %  ok if normalize_vector creates new fields
   normalize_vector (v);
   return v;
}

define vector_sum (a,b)
{
   return vector (a.x+b.x, a.y+b.y, a.z+b.z);
}

define vector_diff (a,b)
{
   return vector (a.x-b.x, a.y-b.y, a.z-b.z);
}

define vector_mul (a, v)
{
   return vector (a*v.x, a*v.y, a*v.z);
}

private define vector_times_scalar (v, a)
{
   return vector_mul (a, v);
}

private define vector_eqs (a, b)
{
   return (a.x == b.x) and (a.y == b.y) and (a.z == b.z);
}

private define vector_neqs (a, b)
{
   return not vector_eqs (a, b);
}

% returns X.x*e1 + X.y*e2 + X.z*e3
define vector_change_basis (X, e1, e2, e3)
{
   return vector_sum (vector_mul (X.x, e1),
		      vector_sum (vector_mul(X.y, e2), vector_mul(X.z, e3)));
}

% Rotate p about n by angle theta.
define vector_rotate (p, n, theta)
{
   variable pn = dotprod (p, n);
   variable c = cos (theta);
   return vector_sum (vector_mul (c,p),
		      vector_sum (vector_mul (pn*(1.0-c),n),
				  vector_mul (sin(theta), crossprod(n,p))));
}

% Given an orthonormal basis x1_hat, y1_hat, and x1_hat cross y1_hat,
% find a rotation axis and angle that will produce this basis
define vector_get_transformation (x1_hat, x2_hat)
{
   variable x3_hat = crossprod (x1_hat, x2_hat);
   variable a1, a2, a3;
   variable b1, b2, b3;
   variable c1, c2, c3;

   a1 = x1_hat.x;		       %  m11
   a2 = x2_hat.y;		       %  m22
   a3 = x3_hat.z;		       %  m33
   b1 = x2_hat.z;		       %  m23
   b2 = x3_hat.x;		       %  m31
   b3 = x1_hat.y;		       %  m12
   c1 = x3_hat.y;		       %  m32
   c2 = x1_hat.z;		       %  m13
   c3 = x2_hat.x;		       %  m21

   % Matrix is:
   %
   %  [a1 b3 c2]
   %  [c3 a2 b1]
   %  [b2 c1 a3]
   %
   
   variable cos_theta = 0.5*(a1+a2+a3-1.0);
   variable sin_theta = sqrt (1.0 - cos_theta*cos_theta);
   if (sin_theta < 1e-12)
     return vector (0, 0, 1), 0.0;
   variable den = 2.0*sin_theta;
   return vector ((b1-c1)/den, (b2-c2)/den, (b3-c3)/den), asin(sin_theta);
}
  
define vector_chs (a)
{
   variable v = @Vector_Type;
   v.x = -a.x;
   v.y = -a.y;
   v.z = -a.z;
   return v;
}

#ifexists __add_unary
% Operator overloading
__add_unary ("sqr", Double_Type, &vector_sqr, Vector_Type);
__add_unary ("abs", Double_Type, &vector_norm, Vector_Type);
__add_unary ("-", Vector_Type, &vector_chs, Vector_Type);

__add_binary ("+", Vector_Type, &vector_sum, Vector_Type, Vector_Type);
__add_binary ("-", Vector_Type, &vector_diff, Vector_Type, Vector_Type);
__add_binary ("*", Double_Type, &dotprod, Vector_Type, Vector_Type);
%__add_binary ("*", Vector_Type, &vector_mul, Array_Type, Vector_Type);
__add_binary ("*", Vector_Type, &vector_mul, Any_Type, Vector_Type);
__add_binary ("*", Vector_Type, &vector_times_scalar, Vector_Type, Any_Type);
__add_binary ("^", Vector_Type, &crossprod, Vector_Type, Vector_Type);

__add_binary ("==", Char_Type, &vector_eqs, Vector_Type, Vector_Type);
__add_binary ("!=", Char_Type, &vector_neqs, Vector_Type, Vector_Type);
#endif
