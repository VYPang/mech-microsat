%
%
% AerospaceUtils/Coord
%
% C
%    CoordinateTransform - Transform between selected coordinate frames and representations.
%
% E
%    ECEFToLLA           - Compute latitude, longitude, altitude from ECEF position.
%    ECIToEF             - Computes the matrix from mean of Aries 2000 to the earth fixed frame.
%    EFToLatLonAlt       - Convert an earth fixed position vector to [latitude;longitude;altitude]
%
% H
%    HorizonAngle        - Angle between the horizon and a vector from rG to rS.
%
% I
%    IntersectPlanet     - Altitude of the nearest point to a sphere.
%
% L
%    LLAToECEF           - Compute ECEF position from latitude, longitude, altitude.
%    LatLonAltToEF       - Convert [latitude;longitude;altitude] to an earth fixed position vector.
%    LatLonToR           - Converts geodetic latitude and longitude to r for an ellipsoidal planet.
%
% Q
%    QAlign              - Rotate about a body axis to align a body vector with an inertial vector.
%    QHills              - Generate the quaternion that transforms from the ECI to the Hills frame.
%    QIToBDot            - Computes the time derivative of a quaternion.
%    QLVLH               - Generate the quaternions that transform from ECI to LVLH coordinates.
%    QRotateToAlign      - Rotate about an axis to align "ua" as close as possible to target "ut"
%
% R
%    R2LatLon            - Computes geocentric latitude and longitude from r
