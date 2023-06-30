#ifndef MILLICAST_EXPORTS_H
#define MILLICAST_EXPORTS_H

#ifdef MILLICAST_API_EXPORT
#define MILLICAST_API __attribute__((visibility ("default")))
#else
#define MILLICAST_API
#endif

#endif // EXPORTS_H
