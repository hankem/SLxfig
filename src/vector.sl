% This routine implements some 3-vector operations.
% Copyright (c) 2004-2008 John E. Davis
% You may distribute this file under the terms the GNU General Public
% License.  See the file COPYING for more information.
%
% Version 0.2.0

#ifnexists sincos
private define sincos(x)
{
   return sin(x), cos(x);
}
#endif

private define help (f)
{
#ifexists _xfig_check_help
   () = _xfig_check_help (0, f; help);
#endif
   throw UsageError, "Illegal usage of $f"$;
}

%!%+
%\datatype{Vector_Type}
%\synopsis{vector data type}
%\description
%  The data type used by various vector functions
%  is defined as a structure with the fields
%#v+
%    x, y, z
%#v-
%  A vector can be initialized, e.g., by
%#v+
%    v = vector(x, y ,z);
%#v-
%  The following common operators can be used for vector arithmetics:
%     +/-  : addition/subtraction of scalars or vectors
%      *   : scaling of vectors or dot product of vectors
%      ^   : cross product of two vectors
%    !=/== : (in)equality of two vectors
%     sqr  : scalar product of a vector with itself
%     abs  : norm of a vector
%\seealso{vector}
%!%-
if (0 == is_defined ("Vector_Type")) typedef struct
{
   x,y,z
}
Vector_Type;

%%%%%%%%%%%%%%%%%%%%%%%%
define vector ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector}
%\synopsis{returns a vector object given by its cartesian or spherical coordinates}
%\usage{Vector_Type vector(Double_Type x, y, z)}
%\altusage{Vector_Type vector(Double_Type r, phi, theta; sph)}
%\qualifiers
%\qualifier{sph}{consider the given coordinates to be spherical (r, phi, theta)}
%\description
%  The components of the vector are returned within the \dtype{Vector_Type}
%  and are accessible like a structure with the fields x, y, and z.
%  If the \var{sph} qualifier is given, the cartesian coordinates are
%  calculated as
%#v+
%    [x, y, z] =
%        r * [cos(phi)*sin(theta), sin(phi)*sin(theta), cos(theta)]
%#v-
%\seealso{Vector_Type}
%!%-
{
   variable x, y, z;
   ifnot (_NARGS) return help(_function_name());
   (x,y,z) = ();

   variable v = @Vector_Type;

   if (__is_numeric (x) != 2)
     x = typecast (x, Double_Type);
   if (__is_numeric (y) != 2)
     y = typecast (y, Double_Type);
   if (__is_numeric (z) != 2)
     z = typecast (z, Double_Type);

   % spherical coordinates given
   if (qualifier_exists("sph"))
   {
     variable sinphi, cosphi, sintheta, costheta;
     (sinphi, cosphi) = sincos(y);
     (sintheta, costheta) = sincos(z);
     (x, y, z) = (x * cosphi * sintheta, x * sinphi * sintheta, x * costheta);
   }

   v.x = x;
   v.y = y;
   v.z = z;
   return v;
}

%%%%%%%%%%%%%%%%%%%%%%%%
define dotprod ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{dotprod}
%\synopsis{calculates the dot product of the given vectors}
%\usage{Double_Type dotprod(Vector_Type a, b)}
%\qualifiers
%  none
%\description
%  The dot product is calculated as
%#v+
%    a.x*b.x + a.y*b.y + a.z*b.z
%#v-
%\seealso{vector}
%!%-
{
   variable a, b;
   ifnot (_NARGS) return help(_function_name());
   (a,b) = ();
   return a.x*b.x + a.y*b.y + a.z*b.z;
}

%%%%%%%%%%%%%%%%%%%%%%%%
define crossprod ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{crossprod}
%\synopsis{calculates the cross product of the given vectors}
%\usage{Vector_Type crossprod(a, b)}
%\qualifiers
%  none
%\description
%  The returned vector is calculated as
%#v+
%    x = a.y*b.z - b.y*a.z
%    y = a.z*b.x - b.z*a.x
%    z = a.x*b.y - b.x*a.y
%#v-
%\seealso{vector}
%!%-
{
   ifnot (_NARGS) return help(_function_name());
   variable a, b; (a,b) = ();
   variable ax=a.x,ay=a.y,az=a.z,bx=b.x,by=b.y,bz=b.z;
   return vector (ay*bz-by*az, az*bx-bz*ax, ax*by-bx*ay);
}

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_sqr ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_sqr}
%\synopsis{returns the scalar product of the given vector with itself}
%\usage{Double_Type vector_sqr(Vector_Type v)}
%\qualifiers
%  none
%\description
%  The scalar product of the given vector is returned using
%#v+
%    dotprod(v, v)
%#v-
%\seealso{dotprod, vector}
%!%-
{
    ifnot (_NARGS) return help(_function_name());
    variable v = ();
    return dotprod (v,v);
}

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_norm ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_norm}
%\synopsis{returns the norm of the given vector}
%\usage{Double_Type vector_norm(Vector_Type v)}
%\qualifiers
%  none
%\description
%  The norm of the given vector is calculated as
%#v+
%    sqrt(v.x^2 + v.y^2 + v.z^2)
%#v-
%\seealso{vector_sqr, vector}
%!%-
{
   ifnot (_NARGS) return help (_function_name());
   variable v = ();
   return hypot (v.x, v.y, v.z);
}

%%%%%%%%%%%%%%%%%%%%%%%%
define normalize_vector ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{normalize_vector}
%\synopsis{normalizes the given vector}
%\usage{normalize_vector(Vector_Type v);}
%\qualifiers
%  none
%\description
%  The given vector is normalized such that
%#v+
%    vector_norm(v) = 1
%#v-
%\seealso{vector_norm, vector}
%!%-
{
   ifnot (_NARGS) return help (_function_name());
   variable v = ();
   variable len = hypot (v.x, v.y, v.z);
   v.x /= len;
   v.y /= len;
   v.z /= len;
}

%%%%%%%%%%%%%%%%%%%%%%%%
define unit_vector ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{unit_vector}
%\synopsis{normalizes the given vector}
%\usage{Vector_Type unit_vector(Vector_Type v)}
%\qualifiers
%  none
%\description
%  The given vector is normalized such that
%#v+
%    vector_norm(v) = 1
%#v-
%\seealso{normalize_vector}
%!%-
{
   ifnot (_NARGS) return help (_function_name());
   variable v = ();
   v = @v; %  ok if normalize_vector creates new fields
   normalize_vector (v);
   return v;
}

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_sum ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_sum}
%\synopsis{calculates the sum of two vectors}
%\usage{Vector_Type vector_sum(Vector_Type a, b)}
%\qualifiers
%  none
%\description
%  The components of the two given vectors are
%  added and the resulting vector is returned.
%  Instead of calling this function, operator
%  arithmetic can be used as well:
%#v+
%    a + b
%#v-
%\seealso{vector_diff, vector}
%!%-
{
   ifnot (_NARGS) return help (_function_name());
   variable a, b; (a,b) = ();
   variable c = @Vector_Type;
   c.x = a.x+b.x; c.y = a.y+b.y; c.z = a.z+b.z;
   return c;
}

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_a_plus_bt ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_a_plus_bt}
%\synopsis{calculates the time dependent sum of two vectors}
%\usage{Vector_Type vector_a_plus_bt(Vector_Type a, b, Double_Type t)}
%\qualifiers
%  none
%\description
%  The components of the second vector are scaled
%  by t and added to the first vector:
%#v+
%    a + t*b
%#v-
%  This can be done by pure operator arithmetic as
%  well as using other functions like
%#v+
%    vector_sum(a, vector_mul(t, b))
%#v-
%\seealso{vector_sum, vector_mul, vector}
%!%-
{
   ifnot (_NARGS) return help (_function_name());
   variable a, b, t; (a, b, t) = ();
   return vector(a.x + t * b.x,
                 a.y + t * b.y,
                 a.z + t * b.z);
}

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_diff ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_diff}
%\synopsis{calculates the difference of two vectors}
%\usage{Vector_Type vector_diff(Vector_Type a, b)}
%\qualifiers
%  none
%\description
%  The components of the two given vectors are
%  subtracted and the resulting vector is returned.
%  Instead of calling this function, operator
%  arithmetic can be used as well:
%#v+
%    a - b
%#v-
%\seealso{vector_sum, vector}
%!%-
{
   ifnot (_NARGS) return help (_function_name());
   variable a, b; (a,b) = ();
   return vector(a.x-b.x, a.y-b.y, a.z-b.z);
}

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_mul ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_mul}
%\synopsis{the given vector is scaled by a scalar}
%\usage{Vector_Type vector_mul(Double_Type a, Vector_Type v)}
%\qualifiers
%  none
%\description
%  The components of the given vector are scaled
%  by a scalar and the resulting vector is returned.
%  Instead of calling this function, operator
%  arithmetic can be used as well:
%#v+
%    a*v
%#v-
%\seealso{vector}
%!%-
{
   ifnot (_NARGS) return help (_function_name());
   variable a, v;  (a, v) = ();
   return vector(a*v.x, a*v.y, a*v.z);
}

% shortcut for vector_mul(a, v)
private define vector_times_scalar (v, a)
{
   return vector_mul (a, v);
}

% logical comparison of the components of two vectors
private define vector_eqs (a, b)
{
   return (a.x == b.x) and (a.y == b.y) and (a.z == b.z);
}

% logical comparison of the components of two vectors
private define vector_neqs (a, b)
{
   return not vector_eqs (a, b);
}

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_change_basis ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_change_basis}
%\synopsis{applies a basis transformation to the given vector}
%\usage{Vector_Type vector_change_basis(Vector_Type v, e1, e2, e3)}
%\qualifiers
%  none
%\description
%  The components of the given vector are transformed into
%  the new basis given by the unit vectors e1, e2 and e3:
%#v+
%    v.x*e1 + v.y*e2 + v.z*e3
%#v-
%\seealso{unit_vector, vector}
%!%-
{
   ifnot (_NARGS) return help (_function_name());
   variable v, e1, e2, e3;
   (v, e1, e2, e3) = ();
   return vector_sum (vector_mul (v.x, e1),
		      vector_sum (vector_mul(v.y, e2), vector_mul(v.z, e3)));
}

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_rotate ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_rotate}
%\synopsis{rotates the given vector around another vector}
%\usage{Vector_Type vector_rotate(Vector_Type v, n, Double_Type theta)}
%\qualifiers
%  none
%\description
%  The vector v is rotated around the given vector n
%  by the angle theta:
%#v+
%      cos(theta)*v
%    + dotprod(v,n)*(1-cos(theta))*n
%    + sin(theta)*crossprod(n,v)
%#v-
%\seealso{dotprod, crossprod, vector}
%!%-
{
   ifnot (_NARGS) return help (_function_name());
   variable p, n, theta; (p,n,theta) = ();
   variable pn = dotprod (p, n);
   variable s, c; (s, c) = sincos (theta);
   return vector_sum (vector_mul (c,p),
		      vector_sum (vector_mul (pn*(1.0-c),n),
				  vector_mul (s, crossprod(n,p))));
}

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_get_transformation ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_get_transformation}
%\synopsis{finds a rotation axis and angle that will produce the given basis}
%\usage{(Vector_Type, Double_Type) vector_get_transformation(Vector_Type x1_hat, y1_hat);}
%\qualifiers
%  none
%\description
%  The orthonormal basis, given by the unit vectors
%  x1_hat, y1_hat and x1_hat cross y1_hat = z1_hat,
%  can be produced by a transformation of the
%  standard orthonormal basis
%#v+
%    (1,0,0), (0,1,0), (0,0,1)
%#v-
%  by rotation around an axis and angle, which are
%  returned by this function.
%\seealso{vector_rotate, vector_change_basis, unit_vector, vector}
%!%-
{
   ifnot (_NARGS) return help(_function_name());
   variable x1_hat, x2_hat; (x1_hat, x2_hat) = ();
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

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_chs ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_chs}
%\synopsis{inverts the given vector}
%\usage{Vector_Type vector_chs(Vector_Type v)}
%\qualifiers
%  none
%\description
%  The components of the given vector are
%  inverted such that
%#v+
%    v + vector_chs(v) = (0, 0, 0)
%#v-
%\seealso{vector_sum, vector}
%!%-
{
   ifnot (_NARGS) return help(_function_name());
   variable a = ();
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

$1 = path_concat (path_concat (path_dirname (__FILE__), "help"), "vector.hlp");
if (NULL != stat_file ($1))
  add_doc_file ($1);
