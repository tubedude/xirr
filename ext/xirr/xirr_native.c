#include <ruby.h>
#include <math.h>

/*
 * Native implementation of the safeguarded-Newton (rtsafe) solver. This mirrors
 * lib/xirr/rtsafe.rb line for line so the two produce the same result; keep them
 * in sync. Flows arrive as an array of [time, amount] pairs (time in years).
 */

#define BRACKET_CEILING 1.0e7

static double present_value(long n, const double *t, const double *amt, double rate) {
    double sum = 0.0;
    long i;
    for (i = 0; i < n; i++) sum += amt[i] / pow(1.0 + rate, t[i]);
    return sum;
}

static double present_value_derivative(long n, const double *t, const double *amt, double rate) {
    double sum = 0.0;
    long i;
    for (i = 0; i < n; i++) sum += -t[i] * amt[i] / pow(1.0 + rate, t[i] + 1.0);
    return sum;
}

/* Raise the floor just enough that the longest-dated discount factor stays finite. */
static double safe_low(long n, const double *t) {
    double max_t = 1.0, v;
    long i;
    for (i = 0; i < n; i++) if (t[i] > max_t) max_t = t[i];
    v = pow(1.0e-290, 1.0 / max_t);
    if (v < 1.0e-6) v = 1.0e-6;
    return v - 1.0;
}

static int straddles_zero(double a, double b) {
    return (a <= 0 && b >= 0) || (a >= 0 && b <= 0);
}

static int inside(double point, double xlo, double xhi) {
    double lo = xlo < xhi ? xlo : xhi;
    double hi = xlo < xhi ? xhi : xlo;
    return point >= lo && point <= hi;
}

/* Returns the rate, or NAN when it can't converge. */
static double rtsafe(long n, const double *t, const double *amt,
                     double guess, double tol, long max_iter) {
    double low = safe_low(n, t);
    double f_low = present_value(n, t, amt, low);
    double high = 1.0, a, b, xlo, xhi, x, f, df, dxold;
    long i;

    /* Expand the upper bound until the NPV changes sign. */
    while (!straddles_zero(f_low, present_value(n, t, amt, high))) {
        high = high * 2 + 1;
        if (high > BRACKET_CEILING) return NAN;
    }
    a = low;
    b = high;

    /* a == low, so the NPV at a is f_low. Orient so it is negative at xlo and
       positive at xhi. */
    if (f_low < 0.0) { xlo = a; xhi = b; }
    else             { xlo = b; xhi = a; }

    x = (guess > a && guess < b) ? guess : (a + b) / 2.0;
    f = present_value(n, t, amt, x);
    df = present_value_derivative(n, t, amt, x);
    dxold = fabs(b - a);

    for (i = 0; i < max_iter; i++) {
        double next, dx, f_next, df_next;
        int newton_usable = 0;

        if (df != 0.0 && inside(x - f / df, xlo, xhi) && fabs(2.0 * f) <= fabs(dxold * df))
            newton_usable = 1;

        if (newton_usable) { dx = f / df;            next = x - dx; }
        else               { dx = (xhi - xlo) / 2.0; next = xlo + dx; }

        if (fabs(dx) < tol) return next;

        f_next = present_value(n, t, amt, next);
        df_next = present_value_derivative(n, t, amt, next);
        if (f_next < 0.0) xlo = next; else xhi = next;

        x = next; f = f_next; df = df_next; dxold = dx;
    }
    return NAN; /* did not converge within the iteration limit */
}

/* Xirr::Native.rtsafe(flows, guess, tolerance, max_iterations) -> Float | nil */
static VALUE rb_rtsafe(VALUE self, VALUE flows, VALUE guess, VALUE tol, VALUE max_iter) {
    long n, i;
    double *t, *amt, rate;
    /* ALLOCV buffers are freed by the GC even if a conversion below raises, so a
       bad element can't leak them. */
    VALUE t_buf, amt_buf;

    Check_Type(flows, T_ARRAY);
    n = RARRAY_LEN(flows);
    t = ALLOCV_N(double, t_buf, n);
    amt = ALLOCV_N(double, amt_buf, n);

    for (i = 0; i < n; i++) {
        VALUE pair = rb_ary_entry(flows, i);
        Check_Type(pair, T_ARRAY);
        t[i] = NUM2DBL(rb_ary_entry(pair, 0));
        amt[i] = NUM2DBL(rb_ary_entry(pair, 1));
    }

    rate = rtsafe(n, t, amt, NUM2DBL(guess), NUM2DBL(tol), NUM2LONG(max_iter));
    ALLOCV_END(t_buf);
    ALLOCV_END(amt_buf);

    if (isnan(rate) || isinf(rate) || rate <= -1.0) return Qnil;
    return DBL2NUM(rate);
}

void Init_xirr_native(void) {
    VALUE mXirr = rb_define_module("Xirr");
    VALUE mNative = rb_define_module_under(mXirr, "Native");
    rb_define_singleton_method(mNative, "rtsafe", rb_rtsafe, 4);
}
