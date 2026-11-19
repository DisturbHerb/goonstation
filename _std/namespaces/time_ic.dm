// TODO: General re-name of `TIME` -> `TIME_REAL`, `TIME_IC` -> `TIME`, too bikeshed-y?

/// Pertaining to in-universe time.
CREATE_NAMESPACE(TIME_IC)

/// The year is 2053.
ADD_TO_NAMESPACE(TIME_IC)(var/const/DEFAULT_YEAR = 2053)
